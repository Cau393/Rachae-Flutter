from decimal import Decimal
from uuid import UUID

from django.core.cache import cache
from django.db.models import Q

from apps.expenses.models import Expense
from apps.groups.models import GroupMember
from apps.ledger.algorithms import compute_group_net_balances, simplify_group_debts

CACHE_TTL_SECONDS = 300
ZERO = Decimal("0")


class LedgerService:
    @staticmethod
    def get_group_balances(group_id) -> dict:
        cache_key = f"ledger:balances:{group_id}"
        cached_payload = cache.get(cache_key)
        if cached_payload is not None:
            return cached_payload

        memberships = (
            GroupMember.objects.filter(
                group_id=group_id,
                is_deleted=False,
                group__is_deleted=False,
            )
            .select_related("user")
            .order_by("created_at", "user__display_name")
        )
        net_balances = compute_group_net_balances(str(group_id))

        payload = {
            "balances": [
                {
                    "user_id": str(membership.user_id),
                    "user_name": membership.user.display_name,
                    "balance": net_balances.get(str(membership.user_id), ZERO),
                }
                for membership in memberships
            ]
        }
        cache.set(cache_key, payload, timeout=CACHE_TTL_SECONDS)
        return payload

    @staticmethod
    def get_simplified_balances(group) -> dict:
        if not group.simplify_debts:
            return {
                "simplify_debts": False,
                "suggestions": [],
            }

        cache_key = f"ledger:simplified:{group.id}"
        cached_payload = cache.get(cache_key)
        if cached_payload is not None:
            return cached_payload

        payload = {
            "simplify_debts": True,
            "suggestions": simplify_group_debts(str(group.id), group.currency),
        }
        cache.set(cache_key, payload, timeout=CACHE_TTL_SECONDS)
        return payload


class ActivityService:
    @staticmethod
    def get_group_activity(group_id) -> list[dict]:
        expense_items = [
            {
                "type": "expense",
                "id": str(expense.id),
                "group_id": str(expense.group_id) if expense.group_id else None,
                "group_name": expense.group.name if expense.group else None,
                "description": expense.description,
                "amount": expense.amount_in_group_currency,
                "currency": expense.group.currency if expense.group else expense.currency,
                "paid_by_id": str(expense.paid_by_id),
                "paid_by_name": expense.paid_by.display_name,
                "created_at": expense.created_at.isoformat(),
                "_sort_at": expense.created_at,
            }
            for expense in Expense.objects.filter(
                group_id=group_id,
                is_deleted=False,
            )
            .select_related("paid_by", "group")
            .order_by("-created_at")
        ]

        try:
            from apps.transactions.models import Transaction
        except ImportError:
            transaction_items = []
        else:
            transaction_items = [
                {
                    "type": "transaction",
                    "id": str(transaction.id),
                    "group_id": str(transaction.group_id) if transaction.group_id else None,
                    "amount": transaction.amount,
                    "currency": transaction.currency,
                    "payer_id": str(transaction.payer_id),
                    "payer_name": transaction.payer.display_name,
                    "receiver_id": str(transaction.receiver_id),
                    "receiver_name": transaction.receiver.display_name,
                    "note": transaction.note,
                    "is_confirmed": transaction.is_confirmed,
                    "created_at": transaction.created_at.isoformat(),
                    "_sort_at": transaction.created_at,
                }
                for transaction in Transaction.objects.filter(
                    group_id=group_id,
                )
                .select_related("payer", "receiver", "group")
                .order_by("-created_at")
            ]

        activity_items = expense_items + transaction_items
        activity_items.sort(key=lambda item: item["_sort_at"], reverse=True)

        for item in activity_items:
            item.pop("_sort_at", None)

        return activity_items

    @staticmethod
    def get_user_activity_feed(
        user,
        *,
        group_id: UUID | None = None,
        page: int = 1,
        limit: int = 20,
    ) -> list[dict]:
        if group_id is not None:
            group_ids = [group_id]
        else:
            group_ids = list(
                GroupMember.objects.filter(
                    user=user,
                    is_deleted=False,
                    group__is_deleted=False,
                ).values_list("group_id", flat=True)
            )
        if not group_ids:
            return []

        expenses = list(
            Expense.objects.filter(
                Q(group_id__in=group_ids)
                | Q(group_id__isnull=True, paid_by=user)
                | Q(group_id__isnull=True, created_by=user)
                | Q(group_id__isnull=True, splits__user=user),
                is_deleted=False,
            )
            .select_related("paid_by", "group")
            .distinct()
            .order_by("-created_at")
        )

        expense_items = [
            {
                "type": "expense",
                "id": str(expense.id),
                "group_id": str(expense.group_id) if expense.group_id else None,
                "group_name": expense.group.name if expense.group else None,
                "description": expense.description,
                "amount": expense.amount_in_group_currency,
                "currency": expense.group.currency if expense.group else expense.currency,
                "paid_by_id": str(expense.paid_by_id),
                "paid_by_name": expense.paid_by.display_name,
                "created_at": expense.created_at.isoformat(),
                "_sort_at": expense.created_at,
            }
            for expense in expenses
        ]

        try:
            from apps.transactions.models import Transaction
        except ImportError:
            transaction_items = []
        else:
            transaction_items = [
                {
                    "type": "transaction",
                    "id": str(transaction.id),
                    "group_id": str(transaction.group_id) if transaction.group_id else None,
                    "amount": transaction.amount,
                    "currency": transaction.currency,
                    "payer_id": str(transaction.payer_id),
                    "payer_name": transaction.payer.display_name,
                    "receiver_id": str(transaction.receiver_id),
                    "receiver_name": transaction.receiver.display_name,
                    "note": transaction.note,
                    "is_confirmed": transaction.is_confirmed,
                    "created_at": transaction.created_at.isoformat(),
                    "_sort_at": transaction.created_at,
                }
                for transaction in Transaction.objects.filter(
                    group_id__in=group_ids,
                )
                .select_related("payer", "receiver", "group")
                .order_by("-created_at")
            ]

        activity_items = expense_items + transaction_items
        activity_items.sort(key=lambda item: item["_sort_at"], reverse=True)

        for item in activity_items:
            item.pop("_sort_at", None)

        offset = (page - 1) * limit
        return activity_items[offset : offset + limit]
