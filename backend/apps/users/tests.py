import uuid
from datetime import timedelta
from unittest.mock import patch

from django.test import TestCase
from django.utils import timezone
from rest_framework.test import APIClient

from apps.expenses.models import Expense
from apps.groups.models import Group, GroupMember
from apps.splits.models import Split
from apps.transactions.models import Transaction
from apps.users.models import FriendInvite, FriendInviteStatus, User


class UsersPhaseThreeTests(TestCase):
    maxDiff = None

    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create(
            supabase_uid=uuid.uuid4(),
            email="user@example.com",
            phone="+5511999999999",
            display_name="Test User",
        )
        self.other_user = User.objects.create(
            supabase_uid=uuid.uuid4(),
            email="other@example.com",
            phone="+5511888888888",
            display_name="Other User",
        )
        self.third_user = User.objects.create(
            supabase_uid=uuid.uuid4(),
            email="third@example.com",
            phone="+5511777777777",
            display_name="Third User",
        )

    def authenticate(self, user=None):
        self.client.force_authenticate(user=user or self.user)

    def test_pairwise_balances_owed_to_me_returns_only_positive_balances(self):
        self.authenticate()
        group = Group.objects.create(name="G", currency="BRL", created_by=self.user)
        GroupMember.objects.create(group=group, user=self.user)
        GroupMember.objects.create(group=group, user=self.other_user)
        GroupMember.objects.create(group=group, user=self.third_user)
        e1 = Expense.objects.create(
            group=group,
            paid_by=self.user,
            amount="60.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="60.00",
            description="D1",
            created_by=self.user,
        )
        Split.objects.create(expense=e1, user=self.user, amount_owed="30.00")
        Split.objects.create(expense=e1, user=self.other_user, amount_owed="30.00")
        e2 = Expense.objects.create(
            group=group,
            paid_by=self.third_user,
            amount="80.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="80.00",
            description="D2",
            created_by=self.third_user,
        )
        Split.objects.create(expense=e2, user=self.third_user, amount_owed="40.00")
        Split.objects.create(expense=e2, user=self.user, amount_owed="40.00")

        all_resp = self.client.get("/api/v1/users/me/pairwise-balances/")
        owed_resp = self.client.get("/api/v1/users/me/pairwise-balances/?owed_to_me=true")

        self.assertEqual(all_resp.status_code, 200)
        self.assertEqual(owed_resp.status_code, 200)
        owed_balances = owed_resp.json()["data"]["balances"]
        self.assertEqual(len(owed_balances), 1)
        self.assertEqual(owed_balances[0]["user"]["id"], str(self.other_user.id))
        self.assertEqual(owed_balances[0]["balance"], "30.00")

    def test_pairwise_balances_owed_to_me_includes_soft_deleted_counterparty(self):
        """Default User manager hides is_deleted=True; balances still include their split debt."""
        self.authenticate()
        group = Group.objects.create(name="G2", currency="BRL", created_by=self.user)
        GroupMember.objects.create(group=group, user=self.user)
        GroupMember.objects.create(group=group, user=self.other_user)
        expense = Expense.objects.create(
            group=group,
            paid_by=self.user,
            amount="10.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="10.00",
            description="Lunch",
            created_by=self.user,
        )
        Split.objects.create(expense=expense, user=self.user, amount_owed="5.00")
        Split.objects.create(expense=expense, user=self.other_user, amount_owed="5.00")

        self.other_user.is_deleted = True
        self.other_user.save(update_fields=["is_deleted", "updated_at"])

        owed_resp = self.client.get("/api/v1/users/me/pairwise-balances/?owed_to_me=true")
        self.assertEqual(owed_resp.status_code, 200)
        owed_balances = owed_resp.json()["data"]["balances"]
        self.assertEqual(len(owed_balances), 1)
        self.assertEqual(owed_balances[0]["user"]["id"], str(self.other_user.id))
        self.assertEqual(owed_balances[0]["balance"], "5.00")

    def test_users_me_requires_authentication(self):
        response = self.client.get("/api/v1/users/me/")

        self.assertEqual(response.status_code, 401)

    def test_users_me_returns_profile_and_balance_summary(self):
        self.authenticate()

        response = self.client.get("/api/v1/users/me/")

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["email"], "user@example.com")
        self.assertEqual(body["display_name"], "Test User")
        self.assertEqual(body["currency"], "BRL")
        self.assertEqual(body["net_balance"], "0.00")

    @patch("core.authentication.verify_supabase_token")
    def test_users_me_accepts_a_bearer_token_and_syncs_the_user(self, mock_verify):
        supabase_uid = uuid.uuid4()
        mock_verify.return_value = {
            "sub": str(supabase_uid),
            "email": "oauth@example.com",
            "user_metadata": {"full_name": "OAuth User"},
        }

        response = self.client.get(
            "/api/v1/users/me/",
            HTTP_AUTHORIZATION="Bearer mocked-token",
        )

        self.assertEqual(response.status_code, 200)
        self.assertTrue(User.objects.filter(supabase_uid=supabase_uid).exists())
        self.assertEqual(response.json()["email"], "oauth@example.com")

    @patch("core.authentication.verify_supabase_token")
    def test_users_me_normalizes_blank_supabase_phone_to_null(self, mock_verify):
        first_uid = uuid.uuid4()
        second_uid = uuid.uuid4()
        mock_verify.side_effect = [
            {
                "sub": str(first_uid),
                "email": "oauth1@example.com",
                "phone": "",
                "user_metadata": {"full_name": "OAuth One"},
            },
            {
                "sub": str(second_uid),
                "email": "oauth2@example.com",
                "phone": "",
                "user_metadata": {"full_name": "OAuth Two"},
            },
        ]

        response_one = self.client.get(
            "/api/v1/users/me/",
            HTTP_AUTHORIZATION="Bearer mocked-token-one",
        )
        response_two = self.client.get(
            "/api/v1/users/me/",
            HTTP_AUTHORIZATION="Bearer mocked-token-two",
        )

        self.assertEqual(response_one.status_code, 200)
        self.assertEqual(response_two.status_code, 200)
        self.assertIsNone(User.objects.get(supabase_uid=first_uid).phone)
        self.assertIsNone(User.objects.get(supabase_uid=second_uid).phone)

    def test_users_me_patch_updates_profile(self):
        self.authenticate()

        response = self.client.patch(
            "/api/v1/users/me/",
            data={"display_name": "Updated Name", "default_currency": "USD"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.display_name, "Updated Name")
        self.assertEqual(self.user.default_currency, "USD")

    @patch("apps.users.tasks.delete_user_data.delay")
    def test_users_me_delete_soft_deletes_and_dispatches_cleanup(self, mock_delay):
        self.authenticate()

        with self.captureOnCommitCallbacks(execute=True):
            response = self.client.delete("/api/v1/users/me/")

        self.assertEqual(response.status_code, 204)
        self.user.refresh_from_db()
        self.assertTrue(self.user.is_deleted)
        self.assertTrue(self.user.email.startswith("deleted-"))
        mock_delay.assert_called_once_with(str(self.user.id))

    def test_users_search_finds_other_users_by_email_and_phone(self):
        self.authenticate()

        response = self.client.get("/api/v1/users/search/?q=8888")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.json()), 1)
        self.assertEqual(response.json()[0]["email"], "other@example.com")

    def test_users_friends_combines_groups_transactions_and_accepted_invites(self):
        self.authenticate()
        group = Group.objects.create(
            name="House",
            currency="BRL",
            created_by=self.user,
        )
        GroupMember.objects.create(group=group, user=self.user)
        GroupMember.objects.create(group=group, user=self.other_user)
        Transaction.objects.create(
            payer=self.user,
            receiver=self.third_user,
            amount="10.00",
            currency="BRL",
        )
        invite_user = User.objects.create(
            supabase_uid=uuid.uuid4(),
            email="invite@example.com",
            phone="+5511666666666",
            display_name="Invite User",
        )
        FriendInvite.objects.create(
            inviter=self.user,
            email=invite_user.email,
            phone=invite_user.phone,
            token="accepted-token",
            status=FriendInviteStatus.ACCEPTED,
            accepted_by=invite_user,
            expires_at=timezone.now() + timedelta(days=1),
        )

        response = self.client.get("/api/v1/users/friends/")

        self.assertEqual(response.status_code, 200)
        emails = {entry["email"] for entry in response.json()}
        self.assertEqual(
            emails,
            {"other@example.com", "third@example.com", "invite@example.com"},
        )

    def test_users_friends_invite_creates_invite_and_returns_share_url(self):
        self.authenticate()

        response = self.client.post(
            "/api/v1/users/friends/invite/",
            data={"email": "invitee@example.com", "phone": "+5511555555555"},
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        invite = FriendInvite.objects.get(email="invitee@example.com")
        self.assertEqual(invite.status, FriendInviteStatus.PENDING)
        self.assertEqual(response.json()["invite_url"], f"http://localhost:3000/login?invite_token={invite.token}")

    def test_users_friends_invite_allows_creating_a_share_link_without_email(self):
        self.authenticate()

        response = self.client.post(
            "/api/v1/users/friends/invite/",
            data={"phone": "+5511555555555"},
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        invite = FriendInvite.objects.get(phone="+5511555555555")
        self.assertIsNone(invite.email)
        self.assertEqual(response.json()["invite_url"], f"http://localhost:3000/login?invite_token={invite.token}")

    def test_users_friends_invite_open_link_without_phone_or_email(self):
        self.authenticate()

        response = self.client.post(
            "/api/v1/users/friends/invite/",
            data={},
            format="json",
        )

        self.assertEqual(response.status_code, 201)
        body = response.json()
        invite = FriendInvite.objects.get(id=body["id"])
        self.assertIsNone(invite.email)
        self.assertIsNone(invite.phone)
        self.assertEqual(body["invite_url"], f"http://localhost:3000/login?invite_token={invite.token}")

    def test_users_friends_accept_open_invite(self):
        invite = FriendInvite.objects.create(
            inviter=self.user,
            email=None,
            phone=None,
            token="open-invite-token",
            expires_at=timezone.now() + timedelta(days=1),
        )
        self.authenticate(self.other_user)

        response = self.client.post(
            "/api/v1/users/friends/accept/",
            data={"token": "open-invite-token"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        invite.refresh_from_db()
        self.assertEqual(invite.status, FriendInviteStatus.ACCEPTED)
        self.assertEqual(invite.accepted_by, self.other_user)

    def test_users_friends_accept_open_invite_inviter_cannot_accept(self):
        FriendInvite.objects.create(
            inviter=self.user,
            email=None,
            phone=None,
            token="own-open-invite",
            expires_at=timezone.now() + timedelta(days=1),
        )
        self.authenticate()

        response = self.client.post(
            "/api/v1/users/friends/accept/",
            data={"token": "own-open-invite"},
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        raw_detail = response.json()["detail"]
        detail_msg = raw_detail[0] if isinstance(raw_detail, list) else raw_detail
        self.assertIn("cannot accept your own", str(detail_msg).lower())

    def test_users_friends_accept_marks_invite_as_accepted(self):
        self.authenticate(self.other_user)
        invite = FriendInvite.objects.create(
            inviter=self.user,
            email=self.other_user.email,
            phone=self.other_user.phone,
            token="accept-me",
            expires_at=timezone.now() + timedelta(days=1),
        )

        response = self.client.post(
            "/api/v1/users/friends/accept/",
            data={"token": "accept-me"},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        invite.refresh_from_db()
        self.assertEqual(invite.status, FriendInviteStatus.ACCEPTED)
        self.assertEqual(invite.accepted_by, self.other_user)

    @patch("apps.users.services.generate_presigned_upload_url")
    def test_avatar_upload_url_returns_presigned_payload(self, mock_presign):
        self.authenticate()
        mock_presign.return_value = "https://uploads.example.com/avatar"

        response = self.client.get(
            "/api/v1/users/me/avatar-upload-url/?content_type=image/png&file_name=avatar.png"
        )

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertEqual(body["upload_url"], "https://uploads.example.com/avatar")
        self.assertTrue(body["file_key"].startswith(f"avatars/{self.user.id}/"))

    def test_avatar_confirm_updates_avatar_url(self):
        self.authenticate()
        file_key = f"avatars/{self.user.id}/avatar.png"

        response = self.client.patch(
            "/api/v1/users/me/avatar-confirm/",
            data={"file_key": file_key},
            format="json",
        )

        self.assertEqual(response.status_code, 200)
        self.user.refresh_from_db()
        self.assertEqual(self.user.avatar_url, file_key)

    def test_user_balance_endpoint_returns_pairwise_total(self):
        self.authenticate()
        group = Group.objects.create(
            name="Dinner Group",
            currency="BRL",
            created_by=self.user,
        )
        GroupMember.objects.create(group=group, user=self.user)
        GroupMember.objects.create(group=group, user=self.other_user)
        expense = Expense.objects.create(
            group=group,
            paid_by=self.user,
            amount="50.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="50.00",
            description="Dinner",
            created_by=self.user,
        )
        Split.objects.create(expense=expense, user=self.user, amount_owed="25.00")
        Split.objects.create(expense=expense, user=self.other_user, amount_owed="25.00")
        Transaction.objects.create(
            group=group,
            payer=self.other_user,
            receiver=self.user,
            amount="10.00",
            currency="BRL",
            is_confirmed=True,
        )
        response = self.client.get(f"/api/v1/users/{self.other_user.id}/balances/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["balance"], "15.00")

    def test_user_balance_endpoint_reduces_owing_after_confirmed_payment(self):
        self.authenticate()
        group = Group.objects.create(
            name="Trip Group",
            currency="BRL",
            created_by=self.other_user,
        )
        GroupMember.objects.create(group=group, user=self.user)
        GroupMember.objects.create(group=group, user=self.other_user)
        expense = Expense.objects.create(
            group=group,
            paid_by=self.other_user,
            amount="50.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="50.00",
            description="Hotel",
            created_by=self.other_user,
        )
        Split.objects.create(expense=expense, user=self.user, amount_owed="25.00")
        Split.objects.create(expense=expense, user=self.other_user, amount_owed="25.00")
        Transaction.objects.create(
            group=group,
            payer=self.user,
            receiver=self.other_user,
            amount="10.00",
            currency="BRL",
            is_confirmed=True,
        )
        response = self.client.get(f"/api/v1/users/{self.other_user.id}/balances/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["balance"], "-15.00")
