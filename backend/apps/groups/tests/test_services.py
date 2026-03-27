from decimal import Decimal
from unittest.mock import patch

from django.test import TestCase

from apps.expenses.models import Expense
from apps.groups.models import Group, GroupMember, GroupRole
from apps.groups.services import BalanceService, GroupService, MemberService
from apps.splits.models import Split

from .base import GroupTestMixin


class GroupServiceTests(GroupTestMixin, TestCase):
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_create_group_assigns_creator_as_admin_and_adds_members(self, mock_delay):
        payload = {
            "name": "Buzios Trip",
            "description": "March trip",
            "type": "trip",
            "currency": "BRL",
            "simplify_debts": True,
            "member_ids": [self.member_user.id, self.viewer_user.id],
        }

        with self.captureOnCommitCallbacks(execute=True):
            group = GroupService.create_group(self.user, payload)

        self.assertEqual(group.name, "Buzios Trip")
        self.assertTrue(GroupMember.objects.filter(group=group, user=self.user, role=GroupRole.ADMIN).exists())
        self.assertTrue(GroupMember.objects.filter(group=group, user=self.member_user, role=GroupRole.MEMBER).exists())
        self.assertTrue(GroupMember.objects.filter(group=group, user=self.viewer_user, role=GroupRole.MEMBER).exists())
        mock_delay.assert_called_once_with(str(group.id))

    def test_update_group_blocks_currency_change_when_expenses_exist(self):
        group = self.create_group()
        Expense.objects.create(
            group=group,
            paid_by=self.user,
            amount="50.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="50.00",
            description="Dinner",
            created_by=self.user,
        )

        with self.assertRaisesMessage(ValueError, "Cannot change currency after expenses have been added."):
            GroupService.update_group(group, {"currency": "USD"})

    def test_delete_group_soft_deletes_instead_of_hard_deleting(self):
        group = self.create_group()

        GroupService.delete_group(group, self.user)

        group.refresh_from_db()
        self.assertTrue(group.is_deleted)
        self.assertTrue(Group.all_objects.filter(id=group.id).exists())

    def test_group_balances_returns_per_member_net_balances(self):
        group = self.create_group()
        self.add_membership(group, self.user, GroupRole.ADMIN)
        self.add_membership(group, self.member_user, GroupRole.MEMBER)

        expense = Expense.objects.create(
            group=group,
            paid_by=self.user,
            amount="60.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="60.00",
            description="Groceries",
            created_by=self.user,
        )
        Split.objects.create(expense=expense, user=self.user, amount_owed="30.00")
        Split.objects.create(expense=expense, user=self.member_user, amount_owed="30.00")

        payload = BalanceService.group_balances(group)

        balances = {item["user_id"]: item["net_balance"] for item in payload["balances"]}
        self.assertEqual(payload["currency"], "BRL")
        self.assertEqual(balances[self.user.id], Decimal("30.00"))
        self.assertEqual(balances[self.member_user.id], Decimal("-30.00"))


class MemberServiceTests(GroupTestMixin, TestCase):
    def setUp(self):
        super().setUp()
        self.group = self.create_group()
        self.add_membership(self.group, self.user, GroupRole.ADMIN)

    def test_add_member_blocks_duplicate_membership(self):
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)

        with self.assertRaisesMessage(ValueError, "User is already a member of this group."):
            MemberService.add_member(self.group, self.member_user.id, GroupRole.MEMBER, self.user)

    def test_remove_member_blocks_removing_last_admin(self):
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        with self.assertRaisesMessage(ValueError, "Cannot remove the group creator."):
            MemberService.remove_member(self.group, self.user.id, self.member_user)

    def test_remove_member_blocks_removing_last_admin_when_target_is_not_creator(self):
        group = self.create_group(created_by=self.other_user)
        self.add_membership(group, self.other_user, GroupRole.MEMBER)
        self.add_membership(group, self.user, GroupRole.ADMIN)
        self.add_membership(group, self.member_user, GroupRole.MEMBER)
        with self.assertRaisesMessage(
            ValueError, "Cannot remove the last admin. Transfer admin role first."
        ):
            MemberService.remove_member(group, self.user.id, self.member_user)

    def test_remove_member_blocks_removing_group_creator_even_with_two_admins(self):
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        mu = GroupMember.objects.get(group=self.group, user=self.member_user)
        mu.role = GroupRole.ADMIN
        mu.save(update_fields=["role"])
        with self.assertRaisesMessage(ValueError, "Cannot remove the group creator."):
            MemberService.remove_member(self.group, self.user.id, self.member_user)

    def test_creator_can_remove_other_admin_when_two_admins(self):
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        mu = GroupMember.objects.get(group=self.group, user=self.member_user)
        mu.role = GroupRole.ADMIN
        mu.save(update_fields=["role"])
        MemberService.remove_member(self.group, self.member_user.id, self.user)
        self.assertFalse(
            GroupMember.objects.filter(group=self.group, user=self.member_user).exists()
        )

    def test_change_role_blocks_demoting_creator_by_other_admin(self):
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        mu = GroupMember.objects.get(group=self.group, user=self.member_user)
        mu.role = GroupRole.ADMIN
        mu.save(update_fields=["role"])
        with self.assertRaisesMessage(ValueError, "Cannot demote the group creator."):
            MemberService.change_role(
                self.group, self.user.id, GroupRole.VIEWER, actor=self.member_user
            )

    def test_creator_can_demote_self_when_not_last_admin(self):
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        mu = GroupMember.objects.get(group=self.group, user=self.member_user)
        mu.role = GroupRole.ADMIN
        mu.save(update_fields=["role"])
        MemberService.change_role(self.group, self.user.id, GroupRole.MEMBER, actor=self.user)
        membership = GroupMember.objects.get(group=self.group, user=self.user)
        self.assertEqual(membership.role, GroupRole.MEMBER)

    def test_leave_group_blocks_last_admin_from_leaving(self):
        with self.assertRaisesMessage(ValueError, "You are the last admin. Transfer the admin role before leaving."):
            MemberService.leave_group(self.group, self.user)

    def test_change_role_blocks_demoting_last_admin(self):
        with self.assertRaisesMessage(ValueError, "Cannot change your own role — you are the last admin."):
            MemberService.change_role(self.group, self.user.id, GroupRole.MEMBER, actor=self.user)
