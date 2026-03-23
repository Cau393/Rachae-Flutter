from unittest.mock import patch

from django.test import TestCase

from apps.groups.models import Group, GroupMember, GroupRole

from .base import GroupTestMixin


class GroupViewTests(GroupTestMixin, TestCase):
    def setUp(self):
        super().setUp()
        self.group = self.create_group()
        self.add_membership(self.group, self.user, GroupRole.ADMIN)
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        self.add_membership(self.group, self.viewer_user, GroupRole.VIEWER)

    def test_get_groups_returns_only_current_users_groups(self):
        self.authenticate(self.user)
        other_group = self.create_group(created_by=self.other_user, name="Other Group")
        self.add_membership(other_group, self.other_user, GroupRole.ADMIN)

        response = self.client.get("/api/v1/groups/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()), 1)
        self.assertEqual(response.json()[0]["id"], str(self.group.id))

    def test_get_eligible_friend_groups_returns_admin_groups_without_existing_friend_membership(self):
        eligible_group = self.create_group(name="Eligible Group")
        self.add_membership(eligible_group, self.user, GroupRole.ADMIN)

        already_joined_group = self.create_group(name="Already Joined")
        self.add_membership(already_joined_group, self.user, GroupRole.ADMIN)
        self.add_membership(already_joined_group, self.other_user, GroupRole.MEMBER)

        member_only_group = self.create_group(name="Member Only")
        self.add_membership(member_only_group, self.user, GroupRole.MEMBER)

        self.authenticate(self.user)

        response = self.client.get(
            f"/api/v1/groups/eligible-friend-groups/?user_id={self.other_user.id}"
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            [item["id"] for item in response.json()],
            [str(eligible_group.id), str(self.group.id)],
        )

    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_post_groups_creates_group_and_admin_membership(self, mock_delay):
        self.authenticate(self.user)

        with self.captureOnCommitCallbacks(execute=True):
            response = self.client.post(
                "/api/v1/groups/",
                data={
                    "name": "Weekend Trip",
                    "description": "Travel budget",
                    "type": "trip",
                    "currency": "BRL",
                    "simplify_debts": True,
                    "member_ids": [str(self.member_user.id)],
                },
                format="json",
            )

        self.assertEqual(response.status_code, 201)
        created_group = Group.objects.get(name="Weekend Trip")
        self.assertTrue(
            GroupMember.objects.filter(group=created_group, user=self.user, role=GroupRole.ADMIN).exists()
        )
        mock_delay.assert_called_once_with(str(created_group.id))

    def test_leave_group_removes_membership(self):
        self.authenticate(self.member_user)

        response = self.client.post(f"/api/v1/groups/{self.group.id}/leave/")

        self.assertEqual(response.status_code, 204)
        self.assertFalse(GroupMember.objects.filter(group=self.group, user=self.member_user).exists())

    def test_simplified_balances_returns_empty_list_when_simplify_debts_is_disabled(self):
        self.group.simplify_debts = False
        self.group.save(update_fields=["simplify_debts"])
        self.authenticate(self.member_user)

        response = self.client.get(f"/api/v1/groups/{self.group.id}/balances/simplified/")

        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.json()["simplify_debts"])
        self.assertEqual(response.json()["suggestions"], [])

    def test_viewer_can_access_read_only_endpoints(self):
        self.authenticate(self.viewer_user)

        detail_response = self.client.get(f"/api/v1/groups/{self.group.id}/")
        members_response = self.client.get(f"/api/v1/groups/{self.group.id}/members/")
        balances_response = self.client.get(f"/api/v1/groups/{self.group.id}/balances/")
        report_response = self.client.get(f"/api/v1/groups/{self.group.id}/report/")

        self.assertEqual(detail_response.status_code, 200)
        self.assertEqual(members_response.status_code, 200)
        self.assertEqual(balances_response.status_code, 200)
        self.assertEqual(report_response.status_code, 200)

    def test_viewer_is_blocked_on_write_endpoints(self):
        self.authenticate(self.viewer_user)

        add_member_response = self.client.post(
            f"/api/v1/groups/{self.group.id}/members/",
            data={"user_id": str(self.other_user.id), "role": GroupRole.MEMBER},
            format="json",
        )
        leave_response = self.client.post(f"/api/v1/groups/{self.group.id}/leave/")
        patch_response = self.client.patch(
            f"/api/v1/groups/{self.group.id}/",
            data={"name": "Blocked"},
            format="json",
        )

        self.assertEqual(add_member_response.status_code, 403)
        self.assertEqual(leave_response.status_code, 403)
        self.assertEqual(patch_response.status_code, 403)

    def test_non_member_gets_forbidden_on_group_detail(self):
        self.authenticate(self.other_user)

        response = self.client.get(f"/api/v1/groups/{self.group.id}/")

        self.assertEqual(response.status_code, 403)
    
    def test_admin_can_update_group(self):
        self.authenticate(self.user)

        response = self.client.patch(
            f"/api/v1/groups/{self.group.id}/",
            data={"name": "Updated Name"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)

        self.group.refresh_from_db()
        self.assertEqual(self.group.name, "Updated Name")
    
    def test_admin_can_delete_group(self):
        self.authenticate(self.user)

        response = self.client.delete(f"/api/v1/groups/{self.group.id}/")

        self.assertEqual(response.status_code, 204)

        self.group.refresh_from_db()
        self.assertTrue(self.group.is_deleted)

    def test_admin_can_add_member(self):
        self.authenticate(self.user)

        response = self.client.post(
            f"/api/v1/groups/{self.group.id}/members/",
            data={"user_id": str(self.other_user.id), "role": GroupRole.MEMBER},
            format="json",
        )

        self.assertEqual(response.status_code, 201)

        self.assertTrue(
            GroupMember.objects.filter(
                group=self.group,
                user=self.other_user
            ).exists()
        )
    
    def test_admin_can_change_member_role(self):
        self.authenticate(self.user)

        response = self.client.patch(
            f"/api/v1/groups/{self.group.id}/members/{self.member_user.id}/",
            data={"role": GroupRole.ADMIN},
            format="json",
        )

        self.assertEqual(response.status_code, 200)

        membership = GroupMember.objects.get(
            group=self.group,
            user=self.member_user
        )

        self.assertEqual(membership.role, GroupRole.ADMIN)
    
    def test_admin_can_remove_member(self):
        self.authenticate(self.user)

        response = self.client.delete(
            f"/api/v1/groups/{self.group.id}/members/{self.member_user.id}/"
        )

        self.assertEqual(response.status_code, 204)

        self.assertFalse(
            GroupMember.objects.filter(
                group=self.group,
                user=self.member_user
            ).exists()
        )
    
    def test_group_balances_endpoint(self):
        self.authenticate(self.member_user)

        response = self.client.get(
            f"/api/v1/groups/{self.group.id}/balances/"
        )

        self.assertEqual(response.status_code, 200)
        self.assertIn("balances", response.json())
    
    def test_member_cannot_update_group(self):
        self.authenticate(self.member_user)

        response = self.client.patch(
            f"/api/v1/groups/{self.group.id}/",
            data={"name": "Fail"},
            format="json"
        )

        self.assertEqual(response.status_code, 403)