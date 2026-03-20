from rest_framework import serializers

from apps.users.models import FriendInvite, User


class CurrencyField(serializers.CharField):
    def to_internal_value(self, data):
        value = super().to_internal_value(data).upper()
        if len(value) != 3 or not value.isalpha():
            raise serializers.ValidationError("Currency must be a valid ISO 4217 code.")
        return value


class CurrentUserSerializer(serializers.ModelSerializer):
    total_owed = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    total_owing = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    net_balance = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)
    currency = serializers.CharField(read_only=True)

    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "display_name",
            "avatar_url",
            "phone",
            "default_currency",
            "preferred_locale",
            "total_owed",
            "total_owing",
            "net_balance",
            "currency",
        ]


class CurrentUserUpdateSerializer(serializers.ModelSerializer):
    default_currency = CurrencyField(max_length=3, required=False)

    class Meta:
        model = User
        fields = [
            "display_name",
            "avatar_url",
            "default_currency",
        ]


class UserSearchQuerySerializer(serializers.Serializer):
    q = serializers.CharField(max_length=255)


class UserSearchResultSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "email",
            "phone",
            "display_name",
            "avatar_url",
        ]


class FriendListSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id",
            "display_name",
            "email",
            "phone",
            "avatar_url",
        ]


class AvatarUploadUrlRequestSerializer(serializers.Serializer):
    content_type = serializers.CharField(max_length=100)
    file_name = serializers.CharField(max_length=255, required=False, allow_blank=True)


class AvatarUploadUrlResponseSerializer(serializers.Serializer):
    upload_url = serializers.URLField()
    file_key = serializers.CharField()
    expires_in = serializers.IntegerField()


class AvatarConfirmSerializer(serializers.Serializer):
    file_key = serializers.CharField(max_length=500)


class FriendInviteCreateSerializer(serializers.Serializer):
    email = serializers.EmailField(required=False, allow_null=True)
    phone = serializers.CharField(max_length=20)


class FriendInviteSerializer(serializers.ModelSerializer):
    class Meta:
        model = FriendInvite
        fields = [
            "id",
            "email",
            "phone",
            "token",
            "status",
            "expires_at",
            "created_at",
        ]


class FriendInviteCreateResponseSerializer(serializers.Serializer):
    id = serializers.UUIDField(source="invite.id")
    email = serializers.EmailField(source="invite.email", allow_null=True)
    phone = serializers.CharField(source="invite.phone")
    token = serializers.CharField(source="invite.token")
    status = serializers.CharField(source="invite.status")
    expires_at = serializers.DateTimeField(source="invite.expires_at")
    created_at = serializers.DateTimeField(source="invite.created_at")
    invite_url = serializers.URLField()


class FriendInviteAcceptSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=128)


class BalanceSerializer(serializers.Serializer):
    balance = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = serializers.CharField()


class BalanceSummarySerializer(serializers.Serializer):
    total_owed = serializers.DecimalField(max_digits=12, decimal_places=2)
    total_owing = serializers.DecimalField(max_digits=12, decimal_places=2)
    net_balance = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = serializers.CharField()
