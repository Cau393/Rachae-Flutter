import uuid
from decimal import Decimal
from importlib import import_module

from django.core.cache import cache
from django.db import transaction
from django.db.models import Q
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied, ValidationError

from apps.currencies.models import ExchangeRate
from apps.expenses.models import Expense
from apps.groups.models import Group, GroupMember
from apps.splits.models import Split
from core.models import AuditLog
from core.storage import generate_presigned_upload_url

ONE_EXCHANGE_RATE = Decimal("1.000000")
RECEIPT_UPLOAD_EXPIRATION_SECONDS = 900


class SplitService:
    """Split calculation helpers for expense creation and updates.

    Examples:
        Equal split with rounding on the last participant:
        >>> SplitService.compute_splits(
        ...     method="equal",
        ...     splits_data=[
        ...         {"user_id": "u1"},
        ...         {"user_id": "u2"},
        ...         {"user_id": "u3"},
        ...     ],
        ...     amount_in_group_currency=Decimal("10.00"),
        ... )
        [
            {"user_id": "u1", "amount_owed": Decimal("3.33"), "share_value": None},
            {"user_id": "u2", "amount_owed": Decimal("3.33"), "share_value": None},
            {"user_id": "u3", "amount_owed": Decimal("3.34"), "share_value": None},
        ]

        Shares split using a 2:1:1 ratio:
        >>> SplitService.compute_splits(
        ...     method="shares",
        ...     splits_data=[
        ...         {"user_id": "u1", "share_value": "2"},
        ...         {"user_id": "u2", "share_value": "1"},
        ...         {"user_id": "u3", "share_value": "1"},
        ...     ],
        ...     amount_in_group_currency=Decimal("10.00"),
        ... )
        [
            {"user_id": "u1", "amount_owed": Decimal("5.00"), "share_value": Decimal("2")},
            {"user_id": "u2", "amount_owed": Decimal("2.50"), "share_value": Decimal("1")},
            {"user_id": "u3", "amount_owed": Decimal("2.50"), "share_value": Decimal("1")},
        ]
    """

    @staticmethod
    def compute_splits(method: str, splits_data: list, amount_in_group_currency: Decimal) -> list:
        """
        Return split payloads ready for `Split.objects.bulk_create()`.

        Each item contains:
        - `user_id`
        - `amount_owed`
        - `share_value`
        """
        total = Decimal(str(amount_in_group_currency)).quantize(Decimal("0.01"))

        if method == "equal":
            return SplitService._compute_equal(splits_data, total)
        if method == "exact":
            return SplitService._compute_exact(splits_data, total)
        if method == "percentage":
            return SplitService._compute_percentage(splits_data, total)
        if method == "shares":
            return SplitService._compute_shares(splits_data, total)

        raise ValueError(f"Unknown split method: {method}")

    @staticmethod
    def validate_splits(method: str, splits_data: list, amount_in_group_currency: Decimal) -> None:
        """Validate split inputs for the selected method."""
        if not splits_data:
            raise ValidationError("At least one split participant is required.")

        user_ids = [split.get("user_id") for split in splits_data]
        if any(user_id is None for user_id in user_ids):
            raise ValidationError("Each split must include user_id.")

        if len(user_ids) != len({str(user_id) for user_id in user_ids}):
            raise ValidationError("Duplicate user_id in splits.")

        total = Decimal(str(amount_in_group_currency)).quantize(Decimal("0.01"))

        if method == "equal":
            return

        if method == "exact":
            SplitService._validate_exact(splits_data, total)
            return

        if method == "percentage":
            SplitService._validate_percentage(splits_data)
            return

        if method == "shares":
            SplitService._validate_shares(splits_data)
            return

        raise ValidationError(f"Unknown split method: {method}")

    @staticmethod
    def _validate_exact(splits_data: list, total: Decimal) -> None:
        computed_total = Decimal("0.00")

        for split in splits_data:
            if split.get("amount_owed") is None:
                raise ValidationError("Each exact split must include amount_owed.")

            amount_owed = Decimal(str(split["amount_owed"])).quantize(Decimal("0.01"))
            if amount_owed < Decimal("0.00"):
                raise ValidationError("Exact split amounts cannot be negative.")
            computed_total += amount_owed

        if abs(computed_total - total) > Decimal("0.01"):
            raise ValidationError(
                f"Split amounts sum to {computed_total} but expense is {total}."
            )

    @staticmethod
    def _validate_percentage(splits_data: list) -> None:
        percentage_total = Decimal("0")

        for split in splits_data:
            if split.get("share_value") is None:
                raise ValidationError("Each percentage split must include share_value.")

            share_value = Decimal(str(split["share_value"]))
            if share_value < Decimal("0"):
                raise ValidationError("Percentage share_value cannot be negative.")
            percentage_total += share_value

        if abs(percentage_total - Decimal("100")) > Decimal("0.01"):
            raise ValidationError(
                f"Percentages sum to {percentage_total}, must be 100."
            )

    @staticmethod
    def _validate_shares(splits_data: list) -> None:
        total_shares = Decimal("0")

        for split in splits_data:
            if split.get("share_value") is None:
                raise ValidationError("Each shares split must include share_value.")

            share_value = Decimal(str(split["share_value"]))
            if share_value <= Decimal("0"):
                raise ValidationError("All share_values must be > 0.")
            total_shares += share_value

        if total_shares <= Decimal("0"):
            raise ValidationError("Total shares must be greater than 0.")

    @staticmethod
    def _compute_equal(splits_data: list, total: Decimal) -> list:
        participant_count = len(splits_data)
        base_amount = (total / Decimal(participant_count)).quantize(Decimal("0.01"))

        computed_splits = [
            {
                "user_id": split["user_id"],
                "amount_owed": base_amount,
                "share_value": None,
            }
            for split in splits_data
        ]

        computed_total = sum(
            split["amount_owed"] for split in computed_splits
        ).quantize(Decimal("0.01"))
        rounding_adjustment = (total - computed_total).quantize(Decimal("0.01"))
        computed_splits[0]["amount_owed"] = (
            computed_splits[0]["amount_owed"] + rounding_adjustment
        ).quantize(Decimal("0.01"))

        return computed_splits

    @staticmethod
    def _compute_exact(splits_data: list, total: Decimal) -> list:
        computed_splits = [
            {
                "user_id": split["user_id"],
                "amount_owed": Decimal(str(split["amount_owed"])).quantize(Decimal("0.01")),
                "share_value": None,
            }
            for split in splits_data
        ]

        computed_total = sum(
            split["amount_owed"] for split in computed_splits
        ).quantize(Decimal("0.01"))
        rounding_adjustment = (total - computed_total).quantize(Decimal("0.01"))
        computed_splits[0]["amount_owed"] = (
            computed_splits[0]["amount_owed"] + rounding_adjustment
        ).quantize(Decimal("0.01"))

        return computed_splits

    @staticmethod
    def _compute_percentage(splits_data: list, total: Decimal) -> list:
        computed_splits = []

        for split in splits_data:
            share_value = Decimal(str(split["share_value"]))
            amount_owed = (
                total * share_value / Decimal("100")
            ).quantize(Decimal("0.01"))
            computed_splits.append(
                {
                    "user_id": split["user_id"],
                    "amount_owed": amount_owed,
                    "share_value": share_value,
                }
            )

        computed_total = sum(
            split["amount_owed"] for split in computed_splits
        ).quantize(Decimal("0.01"))
        rounding_adjustment = (total - computed_total).quantize(Decimal("0.01"))
        computed_splits[0]["amount_owed"] = (
            computed_splits[0]["amount_owed"] + rounding_adjustment
        ).quantize(Decimal("0.01"))

        return computed_splits

    @staticmethod
    def _compute_shares(splits_data: list, total: Decimal) -> list:
        total_shares = sum(Decimal(str(split["share_value"])) for split in splits_data)
        computed_splits = []

        for split in splits_data:
            share_value = Decimal(str(split["share_value"]))
            amount_owed = (total * share_value / total_shares).quantize(Decimal("0.01"))
            computed_splits.append(
                {
                    "user_id": split["user_id"],
                    "amount_owed": amount_owed,
                    "share_value": share_value,
                }
            )

        computed_total = sum(
            split["amount_owed"] for split in computed_splits
        ).quantize(Decimal("0.01"))
        rounding_adjustment = (total - computed_total).quantize(Decimal("0.01"))
        computed_splits[0]["amount_owed"] = (
            computed_splits[0]["amount_owed"] + rounding_adjustment
        ).quantize(Decimal("0.01"))

        return computed_splits


def _schedule_optional_task(module_path: str, task_name: str, *task_args) -> None:
    try:
        task_module = import_module(module_path)
    except ModuleNotFoundError:
        return

    task = getattr(task_module, task_name, None)
    if task is None:
        return

    transaction.on_commit(
        lambda task=task, task_args=task_args: task.delay(*task_args)
    )


def _schedule_group_ledger_recalculation(group_id) -> None:
    if not group_id:
        return

    _schedule_optional_task(
        "tasks.ledger_tasks",
        "recalculate_group_ledger",
        str(group_id),
    )


def _schedule_expense_notification(user_id, expense_id) -> None:
    _schedule_optional_task(
        "tasks.email_tasks",
        "send_expense_notification",
        str(user_id),
        str(expense_id),
    )


def _schedule_receipt_confirmation(file_key: str) -> None:
    _schedule_optional_task(
        "tasks.s3_tasks",
        "s3_confirm_upload",
        file_key,
    )


def _schedule_receipt_delete(file_key: str) -> None:
    _schedule_optional_task(
        "tasks.s3_tasks",
        "delete_s3_object",
        file_key,
    )


def get_exchange_rate(from_currency: str, to_currency: str) -> Decimal:
    from_code = (from_currency or "BRL").upper()
    to_code = (to_currency or "BRL").upper()

    if from_code == to_code:
        return ONE_EXCHANGE_RATE

    cache_key = f"rate:{from_code}:{to_code}"
    cached_rate = cache.get(cache_key)
    if cached_rate is not None:
        return Decimal(str(cached_rate)).quantize(Decimal("0.000001"))

    rate = (
        ExchangeRate.objects.filter(
            base_currency=from_code,
            quote_currency=to_code,
            is_deleted=False,
        )
        .order_by("-fetched_at")
        .values_list("rate", flat=True)
        .first()
    )
    if rate is None:
        raise ValidationError(
            f"Exchange rate not available for {from_code} -> {to_code}."
        )

    cache.set(cache_key, str(rate), timeout=86400)
    return Decimal(str(rate)).quantize(Decimal("0.000001"))


def _normalize_money(value) -> Decimal:
    return Decimal(str(value)).quantize(Decimal("0.01"))


def _serialize_split(split: Split) -> dict:
    return {
        "id": str(split.id),
        "user_id": str(split.user_id),
        "amount_owed": str(split.amount_owed),
        "share_value": str(split.share_value) if split.share_value is not None else None,
        "is_settled": split.is_settled,
    }


def _serialize_expense(expense: Expense) -> dict:
    active_splits = expense.splits.filter(is_deleted=False).order_by("created_at")

    return {
        "id": str(expense.id),
        "group_id": str(expense.group_id) if expense.group_id else None,
        "paid_by_id": str(expense.paid_by_id),
        "amount": str(expense.amount),
        "currency": expense.currency,
        "exchange_rate_to_group_currency": str(expense.exchange_rate_to_group_currency),
        "amount_in_group_currency": str(expense.amount_in_group_currency),
        "description": expense.description,
        "category": expense.category,
        "expense_date": expense.expense_date.isoformat() if expense.expense_date else None,
        "split_method": expense.split_method,
        "receipt_urls": list(expense.receipt_urls or []),
        "created_by_id": str(expense.created_by_id),
        "is_deleted": expense.is_deleted,
        "deleted_at": expense.deleted_at.isoformat() if expense.deleted_at else None,
        "created_at": expense.created_at.isoformat() if expense.created_at else None,
        "updated_at": expense.updated_at.isoformat() if expense.updated_at else None,
        "splits": [_serialize_split(split) for split in active_splits],
    }


class ExpenseService:
    @staticmethod
    def list(requesting_user, filters: dict | None = None):
        filters = filters or {}

        user_group_ids = GroupMember.objects.filter(
            user=requesting_user,
            is_deleted=False,
            group__is_deleted=False,
        ).values_list("group_id", flat=True)

        queryset = (
            Expense.objects.filter(is_deleted=False)
            .select_related("paid_by", "created_by", "group")
            .prefetch_related("splits__user")
            .filter(
                Q(group_id__in=user_group_ids)
                | Q(paid_by=requesting_user)
                | Q(created_by=requesting_user)
                | Q(splits__user=requesting_user)
            )
            .distinct()
        )

        if filters.get("group_id"):
            queryset = queryset.filter(group_id=filters["group_id"])
        if filters.get("date_from"):
            queryset = queryset.filter(expense_date__gte=filters["date_from"])
        if filters.get("date_to"):
            queryset = queryset.filter(expense_date__lte=filters["date_to"])
        if filters.get("category"):
            queryset = queryset.filter(category=filters["category"])
        if filters.get("q"):
            queryset = queryset.filter(description__icontains=filters["q"])

        return queryset.order_by("-expense_date", "-created_at")

    @classmethod
    def get(cls, expense_id, requesting_user, include_deleted: bool = False) -> Expense:
        manager = Expense.all_objects if include_deleted else Expense.objects
        expense = get_object_or_404(
            manager.select_related("paid_by", "created_by", "group").prefetch_related(
                "splits__user"
            ),
            id=expense_id,
        )

        if not cls._is_user_involved(expense, requesting_user):
            raise PermissionDenied("You are not involved in this expense.")

        return expense

    @classmethod
    def create(cls, creator, validated_data: dict) -> Expense:
        payload = dict(validated_data)
        splits_data = payload.pop("splits", None) or []
        group = cls._extract_group(payload)
        currency = (payload.get("currency") or "BRL").upper()
        amount = _normalize_money(payload["amount"])
        rate = get_exchange_rate(currency, group.currency if group else currency)
        amount_in_group_currency = (amount * rate).quantize(Decimal("0.01"))

        payload["amount"] = amount
        payload["currency"] = currency
        payload["created_by"] = creator
        payload["group"] = group
        payload["exchange_rate_to_group_currency"] = rate
        payload["amount_in_group_currency"] = amount_in_group_currency

        split_method = payload.get("split_method", Expense._meta.get_field("split_method").default)
        SplitService.validate_splits(split_method, splits_data, amount_in_group_currency)
        cls._validate_group_participants(group, payload.get("paid_by"), creator, splits_data)

        with transaction.atomic():
            expense = Expense.objects.create(**payload)
            computed_splits = cls._replace_splits(expense, splits_data)
            AuditService.log(
                action="EXPENSE_CREATED",
                actor=creator,
                target=expense,
                before_state=None,
                after_state=_serialize_expense(expense),
            )
            _schedule_group_ledger_recalculation(expense.group_id)
            for split in computed_splits:
                _schedule_expense_notification(split["user_id"], expense.id)

        return expense

    @classmethod
    def full_update(cls, expense: Expense, validated_data: dict, actor) -> Expense:
        payload = dict(validated_data)
        splits_data = payload.pop("splits", None) or []
        cls._validate_immutable_fields(expense, payload)
        before_state = _serialize_expense(expense)

        with transaction.atomic():
            updated_fields = []
            for field, value in payload.items():
                if getattr(expense, field) != value:
                    setattr(expense, field, value)
                    updated_fields.append(field)

            expense.amount = _normalize_money(expense.amount)
            expense.amount_in_group_currency = (
                expense.amount * expense.exchange_rate_to_group_currency
            ).quantize(Decimal("0.01"))

            SplitService.validate_splits(
                expense.split_method,
                splits_data,
                expense.amount_in_group_currency,
            )
            cls._validate_group_participants(
                expense.group,
                expense.paid_by,
                expense.created_by,
                splits_data,
            )

            save_fields = list(dict.fromkeys(updated_fields + ["amount", "amount_in_group_currency", "updated_at"]))
            expense.save(update_fields=save_fields)

            computed_splits = cls._replace_splits(expense, splits_data)
            AuditService.log(
                action="EXPENSE_UPDATED",
                actor=actor,
                target=expense,
                before_state=before_state,
                after_state=_serialize_expense(expense),
            )
            _schedule_group_ledger_recalculation(expense.group_id)
            for split in computed_splits:
                _schedule_expense_notification(split["user_id"], expense.id)

        return expense

    @staticmethod
    def partial_update(expense: Expense, validated_data: dict, actor) -> Expense:
        allowed_fields = {"description", "expense_date", "category"}
        payload = {
            field: value
            for field, value in validated_data.items()
            if field in allowed_fields
        }
        if not payload:
            return expense

        before_state = _serialize_expense(expense)

        with transaction.atomic():
            updated_fields = []
            for field, value in payload.items():
                if getattr(expense, field) != value:
                    setattr(expense, field, value)
                    updated_fields.append(field)

            if not updated_fields:
                return expense

            expense.save(update_fields=updated_fields + ["updated_at"])
            AuditService.log(
                action="EXPENSE_UPDATED",
                actor=actor,
                target=expense,
                before_state=before_state,
                after_state=_serialize_expense(expense),
            )

        return expense

    @staticmethod
    def soft_delete(expense: Expense, actor) -> None:
        before_state = _serialize_expense(expense)

        with transaction.atomic():
            expense.soft_delete()
            AuditService.log(
                action="EXPENSE_DELETED",
                actor=actor,
                target=expense,
                before_state=before_state,
                after_state=None,
            )
            _schedule_group_ledger_recalculation(expense.group_id)

    @staticmethod
    def restore(expense: Expense, actor) -> Expense:
        before_state = _serialize_expense(expense)

        with transaction.atomic():
            expense.is_deleted = False
            expense.deleted_at = None
            expense.save(update_fields=["is_deleted", "deleted_at", "updated_at"])
            AuditService.log(
                action="EXPENSE_RESTORED",
                actor=actor,
                target=expense,
                before_state=before_state,
                after_state=_serialize_expense(expense),
            )
            _schedule_group_ledger_recalculation(expense.group_id)

        return expense

    @classmethod
    def batch_update(cls, updates: list, actor) -> dict:
        updated = 0
        errors = []

        for item in updates:
            expense_id = item.get("id")
            payload = {key: value for key, value in item.items() if key != "id"}

            try:
                expense = Expense.objects.get(id=expense_id, is_deleted=False)
                cls.partial_update(expense, payload, actor)
                updated += 1
            except Expense.DoesNotExist:
                errors.append({"id": str(expense_id), "error": "Not found"})
            except ValidationError as exc:
                errors.append({"id": str(expense_id), "error": exc.detail})
            except PermissionDenied as exc:
                errors.append({"id": str(expense_id), "error": str(exc.detail)})
            except ValueError as exc:
                errors.append({"id": str(expense_id), "error": str(exc)})

        return {
            "updated": updated,
            "errors": errors,
        }

    @staticmethod
    def _extract_group(payload: dict) -> Group | None:
        group = payload.pop("group", None)
        group_id = payload.pop("group_id", None)

        if group is not None:
            return group
        if group_id is None:
            return None

        return get_object_or_404(Group, id=group_id, is_deleted=False)

    @staticmethod
    def _is_user_involved(expense: Expense, user) -> bool:
        if expense.group_id and GroupMember.objects.filter(
            group_id=expense.group_id,
            user=user,
            is_deleted=False,
        ).exists():
            return True

        return (
            expense.paid_by_id == user.id
            or expense.created_by_id == user.id
            or expense.splits.filter(user=user, is_deleted=False).exists()
        )

    @staticmethod
    def _validate_immutable_fields(expense: Expense, payload: dict) -> None:
        if (
            "currency" in payload
            and payload["currency"]
            and payload["currency"].upper() != expense.currency
        ):
            raise ValidationError("Expense currency cannot be changed after creation.")

        if "exchange_rate_to_group_currency" in payload:
            raise ValidationError("Exchange rate is immutable after creation.")

        if "amount_in_group_currency" in payload:
            raise ValidationError("Amount in group currency is managed by the service.")

        group_id = payload.get("group_id")
        if group_id and str(group_id) != str(expense.group_id):
            raise ValidationError("Expense group cannot be changed after creation.")

        group = payload.get("group")
        if group is not None and group.id != expense.group_id:
            raise ValidationError("Expense group cannot be changed after creation.")

        payload.pop("group_id", None)
        payload.pop("group", None)
        payload.pop("exchange_rate_to_group_currency", None)
        payload.pop("amount_in_group_currency", None)
        payload.pop("created_by", None)

    @staticmethod
    def _validate_group_participants(group, paid_by, creator, splits_data: list) -> None:
        if group is None:
            return

        member_ids = {
            str(user_id)
            for user_id in GroupMember.objects.filter(
                group=group,
                is_deleted=False,
            ).values_list("user_id", flat=True)
        }

        required_user_ids = {
            str(creator.id if hasattr(creator, "id") else creator),
        }
        if paid_by is not None:
            required_user_ids.add(str(paid_by.id if hasattr(paid_by, "id") else paid_by))
        required_user_ids.update(str(split["user_id"]) for split in splits_data)

        missing_user_ids = sorted(required_user_ids - member_ids)
        if missing_user_ids:
            raise ValidationError(
                "All expense participants must be active members of the group."
            )

    @staticmethod
    def _replace_splits(expense: Expense, splits_data: list) -> list:
        SplitService.validate_splits(
            expense.split_method,
            splits_data,
            expense.amount_in_group_currency,
        )
        computed_splits = SplitService.compute_splits(
            method=expense.split_method,
            splits_data=splits_data,
            amount_in_group_currency=expense.amount_in_group_currency,
        )

        Split.objects.filter(expense=expense, is_deleted=False).delete()
        Split.objects.bulk_create(
            [
                Split(expense=expense, **split_payload)
                for split_payload in computed_splits
            ]
        )

        return computed_splits


class ReceiptService:
    @staticmethod
    def generate_upload_url(
        expense: Expense,
        requesting_user=None,
        content_type: str = "image/jpeg",
    ) -> dict:
        del requesting_user

        timestamp = timezone.now().strftime("%Y%m%d%H%M%S")
        extension = ReceiptService._extension_for_content_type(content_type)
        file_key = f"receipts/{expense.id}/{timestamp}-{uuid.uuid4()}.{extension}"
        upload_url = generate_presigned_upload_url(
            object_key=file_key,
            content_type=content_type,
            expires_in=RECEIPT_UPLOAD_EXPIRATION_SECONDS,
        )

        return {
            "upload_url": upload_url,
            "file_key": file_key,
            "expires_in": RECEIPT_UPLOAD_EXPIRATION_SECONDS,
        }

    @staticmethod
    def confirm_upload(expense: Expense, file_key: str, actor) -> Expense:
        ReceiptService._validate_receipt_key(expense, file_key)
        if file_key in (expense.receipt_urls or []):
            raise ValidationError("This receipt has already been confirmed.")

        before_state = _serialize_expense(expense)

        with transaction.atomic():
            expense.receipt_urls = list(expense.receipt_urls or []) + [file_key]
            expense.save(update_fields=["receipt_urls", "updated_at"])
            AuditService.log(
                action="RECEIPT_ADDED",
                actor=actor,
                target=expense,
                before_state=before_state,
                after_state=_serialize_expense(expense),
            )
            _schedule_receipt_confirmation(file_key)

        return expense

    @staticmethod
    def remove_receipt(expense: Expense, file_key: str, actor) -> None:
        if file_key not in (expense.receipt_urls or []):
            raise ValidationError("Receipt key not found on this expense.")

        before_state = _serialize_expense(expense)

        with transaction.atomic():
            expense.receipt_urls = [
                existing_key
                for existing_key in (expense.receipt_urls or [])
                if existing_key != file_key
            ]
            expense.save(update_fields=["receipt_urls", "updated_at"])
            AuditService.log(
                action="RECEIPT_REMOVED",
                actor=actor,
                target=expense,
                before_state=before_state,
                after_state=_serialize_expense(expense),
            )
            _schedule_receipt_delete(file_key)

    @staticmethod
    def _validate_receipt_key(expense: Expense, file_key: str) -> None:
        expected_prefix = f"receipts/{expense.id}/"
        if not file_key.startswith(expected_prefix):
            raise ValidationError("Receipt key does not belong to this expense.")

    @staticmethod
    def _extension_for_content_type(content_type: str) -> str:
        normalized_content_type = (content_type or "application/octet-stream").lower()
        extensions = {
            "image/jpeg": "jpg",
            "image/jpg": "jpg",
            "image/png": "png",
            "application/pdf": "pdf",
        }
        return extensions.get(normalized_content_type, "bin")


class AuditService:
    @staticmethod
    def log(action, actor, target, before_state, after_state):
        return AuditLog.objects.create(
            actor=actor,
            action=action,
            target_type="expense",
            target_id=target.id,
            before_state=before_state,
            after_state=after_state,
        )
