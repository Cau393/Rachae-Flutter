import uuid

from django.db import models

from core.models import BaseModel

USER_MODEL = "users.User"


class GroupType(models.TextChoices):
    HOME = "home", "Home"
    TRIP = "trip", "Trip"
    COUPLE = "couple", "Couple"
    OTHER = "other", "Other"


class GroupRole(models.TextChoices):
    ADMIN = "ADMIN", "Admin"
    MEMBER = "MEMBER", "Member"
    VIEWER = "VIEWER", "Viewer"


class Group(BaseModel):
    name = models.CharField(max_length=100)
    description = models.TextField(null=True, blank=True)
    type = models.CharField(max_length=20, choices=GroupType.choices, default=GroupType.OTHER)
    currency = models.CharField(max_length=3, default="BRL")
    created_by = models.ForeignKey(
        USER_MODEL,
        on_delete=models.PROTECT,
        related_name="created_groups",
    )
    simplify_debts = models.BooleanField(default=True)

    class Meta:
        db_table = "groups"
        ordering = ["-created_at"]

    def __str__(self):
        return self.name


class GroupMember(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    is_deleted = models.BooleanField(default=False, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    group = models.ForeignKey(
        "groups.Group",
        on_delete=models.CASCADE,
        related_name="members",
    )
    user = models.ForeignKey(
        USER_MODEL,
        on_delete=models.CASCADE,
        related_name="group_memberships",
    )
    role = models.CharField(max_length=10, choices=GroupRole.choices, default=GroupRole.MEMBER)
    joined_at = models.DateTimeField(auto_now_add=True)
    invited_by = models.ForeignKey(
        USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name="sent_group_invites",
    )

    objects = models.Manager()
    all_objects = models.Manager()

    class Meta:
        db_table = "group_members"
        ordering = ["-joined_at"]
        constraints = [
            models.UniqueConstraint(fields=["group", "user"], name="unique_group_member"),
        ]

    def __str__(self):
        return f"{self.user} in {self.group} as {self.role}"
