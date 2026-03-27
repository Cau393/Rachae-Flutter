from decimal import Decimal
from uuid import UUID

from rest_framework import serializers

from apps.groups.models import Group, GroupMember
from apps.transactions.models import Transaction
from apps.users.models import User
from core.storage import resolve_cloudfront_url


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
    is_offset = serializers.BooleanField(required=False, default=False)
    note = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    proof_urls = serializers.ListField(
        child=serializers.CharField(max_length=2048),
        required=False,
        allow_empty=True,
    )

    def validate_receiver_id(self, value):
        if value == UUID(str(self.context["request"].user.id)):
            raise serializers.ValidationError("You cannot record a payment to yourself.")
        return value

    def validate(self, attrs):
        if attrs.get("is_offset") and attrs.get("group_id") is None:
            raise serializers.ValidationError(
                {"group_id": "Offset settlements require a group."}
            )

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


class OffsetCreditPreviewQuerySerializer(serializers.Serializer):
    with_user = serializers.UUIDField(required=True)
    exclude_group = serializers.UUIDField(required=True)


class OffsetCreditPreviewResponseSerializer(serializers.Serializer):
    credit = serializers.DecimalField(max_digits=12, decimal_places=2, coerce_to_string=True)
    currency = serializers.CharField(max_length=3)


class ProofUploadURLQuerySerializer(serializers.Serializer):
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


class ProofFileKeySerializer(serializers.Serializer):
    file_key = serializers.CharField(max_length=1024)


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
    proof_urls = serializers.SerializerMethodField()

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
            "proof_urls",
            "is_confirmed",
            "is_disputed",
            "created_at",
        ]

    def get_proof_urls(self, obj):
        return [resolve_cloudfront_url(key) for key in (obj.proof_urls or [])]
