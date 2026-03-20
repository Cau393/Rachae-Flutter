from decimal import Decimal
from uuid import UUID

from rest_framework import serializers

from apps.groups.models import Group, GroupMember
from apps.transactions.models import Transaction
from apps.users.models import User


class UserMiniSerializer(serializers.ModelSerializer):
    user_id = serializers.UUIDField(source="id", read_only=True)

    class Meta:
        model = User
        fields = [
            "user_id",
            "display_name",
            "avatar_url",
        ]


class TransactionCreateSerializer(serializers.Serializer):
    receiver_id = serializers.UUIDField(required=True)
    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        min_value=Decimal("0.01"),
        required=True,
    )
    currency = serializers.CharField(max_length=3, required=False, default="BRL")
    group_id = serializers.UUIDField(required=False, allow_null=True)
    note = serializers.CharField(required=False, allow_blank=True, allow_null=True)

    def validate_receiver_id(self, value):
        if value == UUID(str(self.context["request"].user.id)):
            raise serializers.ValidationError("You cannot record a payment to yourself.")
        return value

    def validate(self, attrs):
        group_id = attrs.get("group_id")
        if group_id is None:
            return attrs

        try:
            group = Group.objects.get(id=group_id, is_deleted=False)
        except Group.DoesNotExist:
            raise serializers.ValidationError("Group not found.")

        payer = self.context["request"].user
        receiver_id = attrs["receiver_id"]

        if not GroupMember.objects.filter(
            group=group,
            user=payer,
            is_deleted=False,
        ).exists():
            raise serializers.ValidationError("You are not a member of this group.")

        if not GroupMember.objects.filter(
            group=group,
            user_id=receiver_id,
            is_deleted=False,
        ).exists():
            raise serializers.ValidationError("Receiver is not a member of this group.")

        if "currency" not in self.initial_data:
            attrs["currency"] = group.currency

        return attrs


class TransactionOutputSerializer(serializers.ModelSerializer):
    group_id = serializers.UUIDField(read_only=True, allow_null=True)
    payer = UserMiniSerializer(read_only=True)
    receiver = UserMiniSerializer(read_only=True)
    amount = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        coerce_to_string=True,
        read_only=True,
    )

    class Meta:
        model = Transaction
        fields = [
            "id",
            "group_id",
            "payer",
            "receiver",
            "amount",
            "currency",
            "note",
            "is_confirmed",
            "is_disputed",
            "created_at",
        ]
