from rest_framework import serializers

from apps.notifications.models import DeviceToken, Notification, NotificationPreference


class ActorSerializer(serializers.Serializer):
    user_id = serializers.UUIDField(source="id")
    display_name = serializers.CharField()
    avatar_url = serializers.SerializerMethodField()

    def get_avatar_url(self, obj):
        from core.storage import resolve_cloudfront_url

        return resolve_cloudfront_url(obj.avatar_url) if obj.avatar_url else None


class NotificationSerializer(serializers.ModelSerializer):
    actor = ActorSerializer(read_only=True, allow_null=True)

    class Meta:
        model = Notification
        fields = [
            "id",
            "notification_type",
            "title",
            "body",
            "data",
            "is_read",
            "actor",
            "created_at",
        ]


class NotificationPreferenceSerializer(serializers.ModelSerializer):
    class Meta:
        model = NotificationPreference
        fields = [
            "push_expense_created",
            "push_settlement_recorded",
            "push_group_invitation",
            "email_expense_created",
            "email_settlement_recorded",
        ]

    def validate(self, attrs):
        if self.initial_data is not None:
            allowed = set(self.Meta.fields)
            for key in self.initial_data.keys():
                if key not in allowed:
                    raise serializers.ValidationError(
                        {key: "Unknown preference field."}
                    )
        return attrs


class DeviceTokenSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=500)
    device_type = serializers.ChoiceField(choices=DeviceToken.DEVICE_CHOICES)


class DeviceTokenRemoveSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=500)
