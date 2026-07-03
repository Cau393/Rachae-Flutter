from decimal import Decimal, getcontext

from rest_framework import serializers

from apps.expenses.models import Expense, SplitMethod
from apps.expenses.services import SplitService, get_exchange_rate
from apps.groups.models import Group
from apps.splits.models import Split
from apps.users.models import User
from apps.users.serializers import CurrencyField
from core.storage import resolve_cloudfront_url

EXPENSE_CATEGORY_CHOICES = (
    ("geral", "Geral"),
    ("comida", "Comida"),
    ("transporte", "Transporte"),
    ("moradia", "Moradia"),
    ("lazer", "Lazer"),
    ("viagem", "Viagem"),
    ("utilidades", "Utilidades"),
)


class UserMiniSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "display_name",
            "avatar_url",
        ]


class SplitInputSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    amount_owed = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        required=False,
        allow_null=True,
    )
    share_value = serializers.DecimalField(
        max_digits=10,
        decimal_places=4,
        required=False,
        allow_null=True,
    )


def _validate_split_users_exist(splits_data: list) -> None:
    """Bulk existence check for split participants (replaces per-field N+1 lookup)."""
    user_ids = [split.get("user_id") for split in splits_data]
    existing_ids = set(
        User.objects.filter(id__in=user_ids, is_deleted=False).values_list("id", flat=True)
    )
    missing_ids = list(dict.fromkeys(str(user_id) for user_id in user_ids if user_id not in existing_ids))
    if missing_ids:
        raise serializers.ValidationError(
            {"splits": f"Users {', '.join(missing_ids)} do not exist."}
        )


class SplitOutputSerializer(serializers.ModelSerializer):
    user_id = serializers.UUIDField(read_only=True)
    display_name = serializers.CharField(source="user.display_name", read_only=True)
    avatar_url = serializers.CharField(source="user.avatar_url", read_only=True, allow_null=True)

    class Meta:
        model = Split
        fields = [
            "id",
            "user_id",
            "display_name",
            "avatar_url",
            "amount_owed",
            "share_value",
            "is_settled",
        ]


class ExpenseCreateSerializer(serializers.Serializer):
    group_id = serializers.PrimaryKeyRelatedField(
        source="group",
        queryset=Group.objects.filter(is_deleted=False),
        required=False,
        allow_null=True,
    )
    paid_by = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(is_deleted=False),
    )
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = CurrencyField(max_length=3, required=False, default="BRL")
    description = serializers.CharField(max_length=255)
    category = serializers.ChoiceField(
        choices=EXPENSE_CATEGORY_CHOICES,
        required=False,
        default="geral",
    )
    expense_date = serializers.DateField(required=False)
    split_method = serializers.ChoiceField(
        choices=SplitMethod.choices,
        required=False,
        default=Expense._meta.get_field("split_method").default,
    )
    splits = SplitInputSerializer(many=True)

    def validate_amount(self, value):
        if value <= Decimal("0.00"):
            raise serializers.ValidationError("Amount must be greater than 0.")
        return value

    def validate_split_method(self, value):
        valid_methods = {choice for choice, _label in SplitMethod.choices}
        if value not in valid_methods:
            raise serializers.ValidationError("Invalid split method.")
        return value

    def validate(self, attrs):
        getcontext().prec = 28
        split_method = attrs.get(
            "split_method",
            Expense._meta.get_field("split_method").default,
        )
        splits_data = attrs.get("splits", [])
        amount = Decimal(str(attrs["amount"]))
        currency = attrs.get("currency", "BRL")
        group = attrs.get("group")
        target_currency = group.currency if group is not None else currency
        exchange_rate = get_exchange_rate(currency, target_currency)
        amount_in_group_currency = amount * exchange_rate
        amount_in_group_currency = amount_in_group_currency.quantize(Decimal("0.01"))

        _validate_split_users_exist(splits_data)
        SplitService.validate_splits(
            split_method,
            splits_data,
            amount_in_group_currency,
        )

        return attrs


class ExpenseUpdateSerializer(serializers.Serializer):
    group_id = serializers.UUIDField(required=False, allow_null=True)
    paid_by = serializers.PrimaryKeyRelatedField(
        queryset=User.objects.filter(is_deleted=False),
    )
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = CurrencyField(max_length=3, required=False)
    description = serializers.CharField(max_length=255)
    category = serializers.ChoiceField(
        choices=EXPENSE_CATEGORY_CHOICES,
        required=False,
        default="geral",
    )
    expense_date = serializers.DateField(required=False)
    split_method = serializers.ChoiceField(choices=SplitMethod.choices)
    splits = SplitInputSerializer(many=True)

    def validate_amount(self, value):
        if value <= Decimal("0.00"):
            raise serializers.ValidationError("Amount must be greater than 0.")
        return value

    def validate(self, attrs):
        expense = self.context["expense"]

        if "group_id" in attrs and attrs["group_id"] != expense.group_id:
            raise serializers.ValidationError(
                {"group_id": "Expense group cannot be changed after creation."}
            )

        amount = Decimal(str(attrs["amount"])).quantize(Decimal("0.01"))
        amount_in_group_currency = (
            amount * expense.exchange_rate_to_group_currency
        ).quantize(Decimal("0.01"))

        splits_data = attrs.get("splits", [])
        _validate_split_users_exist(splits_data)
        SplitService.validate_splits(
            attrs["split_method"],
            splits_data,
            amount_in_group_currency,
        )

        return attrs


class ExpensePartialUpdateSerializer(serializers.Serializer):
    description = serializers.CharField(max_length=255, required=False)
    category = serializers.ChoiceField(
        choices=EXPENSE_CATEGORY_CHOICES,
        required=False,
    )
    expense_date = serializers.DateField(required=False)

    def validate(self, attrs):
        if not attrs:
            raise serializers.ValidationError(
                "At least one of description, category, or expense_date is required."
            )
        return attrs


class ReceiptUploadURLQuerySerializer(serializers.Serializer):
    content_type = serializers.ChoiceField(
        choices=[
            "image/jpeg",
            "image/jpg",
            "image/png",
            "application/pdf",
        ],
        required=False,
        default="image/jpeg",
    )


class ReceiptFileKeySerializer(serializers.Serializer):
    file_key = serializers.CharField(max_length=1024)


class ExpenseDetailSerializer(serializers.ModelSerializer):
    group_id = serializers.UUIDField(read_only=True, allow_null=True)
    paid_by = UserMiniSerializer(read_only=True)
    created_by = UserMiniSerializer(read_only=True)
    splits = serializers.SerializerMethodField()
    receipt_urls = serializers.SerializerMethodField()

    class Meta:
        model = Expense
        fields = [
            "id",
            "group_id",
            "paid_by",
            "amount",
            "currency",
            "exchange_rate_to_group_currency",
            "amount_in_group_currency",
            "description",
            "category",
            "expense_date",
            "split_method",
            "splits",
            "receipt_urls",
            "created_by",
            "is_deleted",
            "deleted_at",
            "created_at",
            "updated_at",
        ]

    def get_splits(self, obj):
        splits = obj.splits.filter(is_deleted=False).select_related("user").order_by("created_at")
        return SplitOutputSerializer(splits, many=True).data

    def get_receipt_urls(self, obj):
        return [resolve_cloudfront_url(key) for key in (obj.receipt_urls or [])]


class ExpenseListSerializer(serializers.ModelSerializer):
    group_id = serializers.UUIDField(read_only=True, allow_null=True)
    paid_by = UserMiniSerializer(read_only=True)
    split_count = serializers.SerializerMethodField()

    class Meta:
        model = Expense
        fields = [
            "id",
            "group_id",
            "paid_by",
            "amount",
            "currency",
            "amount_in_group_currency",
            "description",
            "category",
            "expense_date",
            "split_method",
            "split_count",
            "is_deleted",
            "created_at",
        ]

    def get_split_count(self, obj):
        prefetched_splits = getattr(obj, "_prefetched_objects_cache", {}).get("splits")
        if prefetched_splits is not None:
            return sum(1 for split in prefetched_splits if not split.is_deleted)
        return obj.splits.filter(is_deleted=False).count()


class BatchUpdateItemSerializer(serializers.Serializer):
    id = serializers.UUIDField()
    category = serializers.ChoiceField(
        choices=EXPENSE_CATEGORY_CHOICES,
        required=False,
    )
    expense_date = serializers.DateField(required=False)

    def validate(self, attrs):
        if "category" not in attrs and "expense_date" not in attrs:
            raise serializers.ValidationError(
                "Each batch update item must include category and/or expense_date."
            )
        return attrs


class BatchUpdateSerializer(serializers.Serializer):
    updates = BatchUpdateItemSerializer(many=True)

    def validate_updates(self, value):
        if not value:
            raise serializers.ValidationError("At least one update item is required.")
        return value
