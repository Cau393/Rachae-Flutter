from decimal import Decimal

from django.apps import apps
from rest_framework import serializers

from apps.groups.models import Group, GroupMember, GroupRole, GroupType


class CurrencyField(serializers.CharField):
    def to_internal_value(self, data):
        value = super().to_internal_value(data).upper()
        if len(value) != 3 or not value.isalpha():
            raise serializers.ValidationError("Currency must be a valid ISO 4217 code.")
        return value


class GroupMemberSerializer(serializers.ModelSerializer):
    user_id = serializers.UUIDField(read_only=True)
    display_name = serializers.CharField(source="user.display_name", read_only=True)
    avatar_url = serializers.CharField(source="user.avatar_url", read_only=True, allow_null=True)
    invited_by = serializers.UUIDField(source="invited_by_id", read_only=True, allow_null=True)

    class Meta:
        model = GroupMember
        fields = [
            "user_id",
            "display_name",
            "avatar_url",
            "role",
            "joined_at",
            "invited_by",
        ]


class BalanceItemSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    display_name = serializers.CharField()
    net_balance = serializers.DecimalField(max_digits=12, decimal_places=2)


class SimplifiedBalanceItemSerializer(serializers.Serializer):
    payer_id = serializers.UUIDField()
    payer_name = serializers.CharField()
    receiver_id = serializers.UUIDField()
    receiver_name = serializers.CharField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)


class GroupListSerializer(serializers.ModelSerializer):
    member_count = serializers.SerializerMethodField()
    your_net_balance = serializers.SerializerMethodField()

    class Meta:
        model = Group
        fields = [
            "id",
            "name",
            "type",
            "currency",
            "member_count",
            "your_net_balance",
            "created_at",
        ]

    def get_member_count(self, obj):
        return getattr(obj, "member_count", obj.members.count())

    def get_your_net_balance(self, obj):
        return getattr(obj, "your_net_balance", Decimal("0.00"))


class GroupCreateSerializer(serializers.ModelSerializer):
    type = serializers.ChoiceField(choices=GroupType.choices, required=False, default=GroupType.OTHER)
    currency = CurrencyField(max_length=3, required=False)
    member_ids = serializers.ListField(
        child=serializers.UUIDField(),
        required=False,
        allow_empty=True,
    )

    class Meta:
        model = Group
        fields = [
            "name",
            "description",
            "type",
            "currency",
            "simplify_debts",
            "member_ids",
        ]

    def validate_member_ids(self, value):
        if len(value) != len(set(value)):
            raise serializers.ValidationError("Member IDs must be unique.")

        if not value:
            return value

        user_model = apps.get_model("users", "User")
        existing_ids = set(user_model.objects.filter(id__in=value).values_list("id", flat=True))
        missing_ids = [str(user_id) for user_id in value if user_id not in existing_ids]
        if missing_ids:
            raise serializers.ValidationError("Some member IDs do not match active users.")

        return value


class GroupDetailSerializer(serializers.ModelSerializer):
    created_by = serializers.UUIDField(source="created_by_id", read_only=True)
    members = GroupMemberSerializer(many=True, read_only=True)
    net_balances = BalanceItemSerializer(many=True, read_only=True)

    class Meta:
        model = Group
        fields = [
            "id",
            "name",
            "description",
            "type",
            "currency",
            "simplify_debts",
            "created_by",
            "members",
            "net_balances",
            "created_at",
        ]


class GroupUpdateSerializer(serializers.ModelSerializer):
    currency = CurrencyField(max_length=3, required=False)

    class Meta:
        model = Group
        fields = [
            "name",
            "description",
            "currency",
            "simplify_debts",
        ]


class BalancesSerializer(serializers.Serializer):
    group_id = serializers.UUIDField()
    currency = serializers.CharField()
    balances = BalanceItemSerializer(many=True)


class SimplifiedBalancesSerializer(serializers.Serializer):
    group_id = serializers.UUIDField()
    currency = serializers.CharField()
    simplify_debts = serializers.BooleanField()
    suggestions = SimplifiedBalanceItemSerializer(many=True)


class AddMemberSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    role = serializers.ChoiceField(choices=GroupRole.choices, required=False, default=GroupRole.MEMBER)


class MemberRoleChangeSerializer(serializers.Serializer):
    role = serializers.ChoiceField(choices=GroupRole.choices)


class GroupReportQuerySerializer(serializers.Serializer):
    from_date = serializers.DateField(required=False, allow_null=True, source="from")
    to_date = serializers.DateField(required=False, allow_null=True, source="to")


class ReportPerPersonSpendSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    display_name = serializers.CharField()
    total_paid = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_owed = serializers.DecimalField(max_digits=12, decimal_places=2)
    net = serializers.DecimalField(max_digits=12, decimal_places=2)


class GroupReportSerializer(serializers.Serializer):
    group_id = serializers.UUIDField()
    group_name = serializers.CharField()
    currency = serializers.CharField()
    date_from = serializers.DateField(allow_null=True)
    date_to = serializers.DateField(allow_null=True)
    total_spent = serializers.DecimalField(max_digits=12, decimal_places=2)
    per_person_spend = ReportPerPersonSpendSerializer(many=True)
    expenses = serializers.ListField(child=serializers.DictField(), allow_empty=True)
    settlements = serializers.ListField(child=serializers.DictField(), allow_empty=True)
