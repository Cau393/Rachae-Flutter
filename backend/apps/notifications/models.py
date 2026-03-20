import uuid

from django.db import models


class NotificationType(models.TextChoices):
    EXPENSE_CREATED = "expense_created", "New expense added"
    EXPENSE_DELETED = "expense_deleted", "Expense deleted"
    SETTLEMENT_RECORDED = "settlement_recorded", "Payment recorded"
    SETTLEMENT_CONFIRMED = "settlement_confirmed", "Payment confirmed"
    GROUP_INVITATION = "group_invitation", "Group invitation"
    MEMBER_ADDED = "member_added", "Added to group"
    WEEKLY_DIGEST = "weekly_digest", "Weekly balance digest"


class Notification(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    recipient = models.ForeignKey(
        "users.User",
        on_delete=models.PROTECT,
        related_name="notifications",
    )
    actor = models.ForeignKey(
        "users.User",
        on_delete=models.PROTECT,
        null=True,
        blank=True,
        related_name="triggered_notifications",
    )
    notification_type = models.CharField(max_length=50, choices=NotificationType.choices)
    title = models.CharField(max_length=255)
    body = models.CharField(max_length=500)
    data = models.JSONField(default=dict)
    is_read = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "notifications"
        ordering = ["-created_at"]
        indexes = [
            models.Index(fields=["recipient", "is_read"]),
            models.Index(fields=["recipient", "created_at"]),
        ]


class DeviceToken(models.Model):
    DEVICE_CHOICES = [("ios", "iOS"), ("android", "Android"), ("web", "Web")]
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        "users.User",
        on_delete=models.CASCADE,
        related_name="device_tokens",
    )
    token = models.CharField(max_length=500, unique=True)
    device_type = models.CharField(max_length=10, choices=DEVICE_CHOICES)
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "device_tokens"
        indexes = [models.Index(fields=["user"])]


class NotificationPreference(models.Model):
    user = models.OneToOneField(
        "users.User",
        on_delete=models.CASCADE,
        related_name="notification_preference",
    )
    push_expense_created = models.BooleanField(default=True)
    push_settlement_recorded = models.BooleanField(default=True)
    push_group_invitation = models.BooleanField(default=True)
    email_expense_created = models.BooleanField(default=True)
    email_settlement_recorded = models.BooleanField(default=True)
    email_weekly_digest = models.BooleanField(default=True)

    class Meta:
        db_table = "notification_preferences"
