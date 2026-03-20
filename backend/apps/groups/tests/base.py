import uuid

from rest_framework.test import APIClient

from apps.groups.models import Group, GroupMember, GroupRole, GroupType
from apps.users.models import User


class GroupTestMixin:
    def setUp(self):
        super().setUp()
        self.client = APIClient()
        self.user = self.create_user("owner@example.com", "+5511999999999", "Owner User")
        self.member_user = self.create_user("member@example.com", "+5511888888888", "Member User")
        self.viewer_user = self.create_user("viewer@example.com", "+5511777777777", "Viewer User")
        self.other_user = self.create_user("other@example.com", "+5511666666666", "Other User")

    def create_user(self, email: str, phone: str, display_name: str) -> User:
        return User.objects.create(
            supabase_uid=uuid.uuid4(),
            email=email,
            phone=phone,
            display_name=display_name,
        )

    def create_group(
        self,
        *,
        created_by=None,
        name: str = "Trip Group",
        description: str | None = None,
        group_type: str = GroupType.TRIP,
        currency: str = "BRL",
        simplify_debts: bool = True,
    ) -> Group:
        return Group.objects.create(
            name=name,
            description=description,
            type=group_type,
            currency=currency,
            created_by=created_by or self.user,
            simplify_debts=simplify_debts,
        )

    def add_membership(self, group: Group, user: User, role: str = GroupRole.MEMBER, invited_by=None) -> GroupMember:
        return GroupMember.objects.create(
            group=group,
            user=user,
            role=role,
            invited_by=invited_by,
        )

    def authenticate(self, user=None):
        self.client.force_authenticate(user=user or self.user)
