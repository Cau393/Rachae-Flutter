from django.db import IntegrityError
from django.test import TestCase

from apps.groups.models import GroupMember, GroupRole, GroupType
from apps.groups.queries import admin_count, get_user_groups

from .base import GroupTestMixin


class GroupModelTests(GroupTestMixin, TestCase):
    def test_group_creation_uses_expected_defaults(self):
        group = self.create_group(created_by=self.user, name="Home", description="Shared bills", group_type=GroupType.HOME)

        self.assertEqual(group.name, "Home")
        self.assertEqual(group.description, "Shared bills")
        self.assertEqual(group.type, GroupType.HOME)
        self.assertEqual(group.currency, "BRL")
        self.assertTrue(group.simplify_debts)
        self.assertFalse(group.is_deleted)

    def test_group_member_unique_constraint_is_enforced(self):
        group = self.create_group()
        self.add_membership(group, self.user, GroupRole.ADMIN)

        with self.assertRaises(IntegrityError):
            GroupMember.objects.create(group=group, user=self.user, role=GroupRole.MEMBER)

    def test_admin_count_changes_after_role_updates(self):
        group = self.create_group()
        owner_membership = self.add_membership(group, self.user, GroupRole.ADMIN)
        self.add_membership(group, self.member_user, GroupRole.ADMIN)

        self.assertEqual(admin_count(group), 2)

        owner_membership.role = GroupRole.MEMBER
        owner_membership.save(update_fields=["role"])

        self.assertEqual(admin_count(group), 1)

    def test_get_user_groups_excludes_soft_deleted_groups(self):
        active_group = self.create_group(name="Active")
        deleted_group = self.create_group(name="Deleted")
        self.add_membership(active_group, self.user, GroupRole.ADMIN)
        self.add_membership(deleted_group, self.user, GroupRole.ADMIN)
        deleted_group.soft_delete()

        groups = list(get_user_groups(self.user))

        self.assertEqual([group.id for group in groups], [active_group.id])
