import logging

from apps.notifications.models import DeviceToken, Notification, NotificationPreference

logger = logging.getLogger(__name__)

_PREF_FIELD_MAP = {
    "expense_created": "push_expense_created",
    "settlement_recorded": "push_settlement_recorded",
    "settlement_confirmed": "push_settlement_recorded",
    "group_invitation": "push_group_invitation",
    "member_added": "push_group_invitation",
}


class NotificationService:
    @staticmethod
    def create(recipient, notification_type, title, body, data=None, actor=None):
        return Notification.objects.create(
            recipient=recipient,
            actor=actor,
            notification_type=notification_type,
            title=title,
            body=body,
            data=data or {},
        )

    @staticmethod
    def unread_count(user):
        return Notification.objects.filter(recipient=user, is_read=False).count()

    @staticmethod
    def mark_read(notification: Notification) -> None:
        if not notification.is_read:
            notification.is_read = True
            notification.save(update_fields=["is_read"])

    @staticmethod
    def mark_all_read(user) -> int:
        updated = Notification.objects.filter(recipient=user, is_read=False).update(is_read=True)
        return updated

    @staticmethod
    def push_allowed(user, notification_type: str) -> bool:
        pref_field = _PREF_FIELD_MAP.get(notification_type)
        if not pref_field:
            return True
        pref = PreferenceService.get_or_create(user)
        return getattr(pref, pref_field, True)


class DeviceTokenService:
    @staticmethod
    def register(user, token: str, device_type: str) -> DeviceToken:
        obj, _ = DeviceToken.objects.update_or_create(
            token=token,
            defaults={"user": user, "device_type": device_type},
        )
        return obj

    @staticmethod
    def remove(user, token: str) -> None:
        DeviceToken.objects.filter(user=user, token=token).delete()

    @staticmethod
    def get_tokens(user) -> list[str]:
        return list(DeviceToken.objects.filter(user=user).values_list("token", flat=True))


class PreferenceService:
    @staticmethod
    def get_or_create(user) -> NotificationPreference:
        pref, _ = NotificationPreference.objects.get_or_create(user=user)
        return pref

    @staticmethod
    def update(pref: NotificationPreference, data: dict) -> NotificationPreference:
        allowed_fields = {f.name for f in NotificationPreference._meta.fields} - {"id", "user"}
        for field, value in data.items():
            if field not in allowed_fields:
                from rest_framework.exceptions import ValidationError

                raise ValidationError({field: "Unknown preference field."})
            setattr(pref, field, value)
        pref.save(update_fields=list(data.keys()))
        return pref
