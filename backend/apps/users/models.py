from django.db import models

from core.models import BaseModel


class FriendInviteStatus(models.TextChoices):
    PENDING = "pending", "Pending"
    ACCEPTED = "accepted", "Accepted"
    EXPIRED = "expired", "Expired"


class User(BaseModel):
    # Django AUTH_USER_MODEL contract (django.contrib.auth.checks.check_user_model)
    USERNAME_FIELD = "email"
    REQUIRED_FIELDS: list[str] = []

    supabase_uid = models.UUIDField(unique=True, db_index=True)
    email = models.EmailField(unique=True)
    phone = models.CharField(max_length=20, unique=True, null=True, blank=True)
    display_name = models.CharField(max_length=100)
    avatar_url = models.TextField(null=True, blank=True)
    preferred_locale = models.CharField(max_length=10, default="pt_BR")
    default_currency = models.CharField(max_length=3, default="BRL")
    is_ad_free = models.BooleanField(default=False)
    stripe_customer_id = models.CharField(max_length=50, unique=True, null=True, blank=True)
    subscription_status = models.CharField(max_length=20, null=True, blank=True)
    plan_expires_at = models.DateTimeField(null=True, blank=True)
    plan_type = models.CharField(max_length=10, null=True, blank=True)

    class Meta:
        db_table = "users"
        ordering = ["-created_at"]

    @property
    def is_authenticated(self):
        return True

    @property
    def is_anonymous(self):
        return False

    def __str__(self):
        return self.email


class FriendInvite(BaseModel):
    inviter = models.ForeignKey(
        "users.User",
        on_delete=models.PROTECT,
        related_name="sent_friend_invites",
    )
    email = models.EmailField(null=True, blank=True, db_index=True)
    phone = models.CharField(max_length=20, null=True, blank=True, db_index=True)
    token = models.CharField(max_length=128, unique=True)
    status = models.CharField(max_length=10, choices=FriendInviteStatus.choices, default=FriendInviteStatus.PENDING)
    expires_at = models.DateTimeField(db_index=True)
    accepted_by = models.ForeignKey(
        "users.User",
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="accepted_friend_invites",
    )

    class Meta:
        db_table = "friend_invites"
        ordering = ["-created_at"]
