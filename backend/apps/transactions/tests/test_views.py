from unittest.mock import patch

from django.test import TestCase, override_settings

from apps.transactions.models import Transaction
from core.models import AuditLog

from .test_services import TransactionTestMixin


class TransactionViewTests(TransactionTestMixin, TestCase):
    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    def test_post_transactions_returns_201_with_pending_transaction(self, mock_delay):
        self.authenticate(self.user)

        with self.captureOnCommitCallbacks(execute=True):
            response = self.client.post(
                "/api/v1/transactions/",
                data={
                    "receiver_id": str(self.member_user.id),
                    "group_id": str(self.group.id),
                    "amount": "15.00",
                    "note": "Partial settlement",
                },
                format="json",
            )

        self.assertEqual(response.status_code, 201)
        payload = response.json()["data"]
        transaction = Transaction.objects.get(id=payload["id"])

        self.assertFalse(payload["is_confirmed"])
        self.assertFalse(payload["is_disputed"])
        self.assertEqual(payload["payer"]["user_id"], str(self.user.id))
        self.assertEqual(payload["receiver"]["user_id"], str(self.member_user.id))
        self.assertEqual(transaction.amount, transaction.amount.__class__("15.00"))
        self.assertEqual(mock_delay.call_count, 1)

    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    def test_post_transactions_rejects_self_payment(self, mock_delay):
        self.authenticate(self.user)

        response = self.client.post(
            "/api/v1/transactions/",
            data={
                "receiver_id": str(self.user.id),
                "group_id": str(self.group.id),
                "amount": "15.00",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["receiver_id"][0], "You cannot record a payment to yourself.")
        mock_delay.assert_not_called()

    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    def test_post_transactions_rejects_receiver_not_in_group(self, mock_delay):
        self.authenticate(self.user)

        response = self.client.post(
            "/api/v1/transactions/",
            data={
                "receiver_id": str(self.other_user.id),
                "group_id": str(self.group.id),
                "amount": "15.00",
            },
            format="json",
        )

        self.assertEqual(response.status_code, 400)
        self.assertEqual(
            response.json()["non_field_errors"][0],
            "Receiver is not a member of this group.",
        )
        mock_delay.assert_not_called()

    def test_list_transactions_returns_only_involved_transactions(self):
        included = self.create_transaction(payer=self.user, receiver=self.member_user, amount="9.00")
        self.create_transaction(payer=self.member_user, receiver=self.third_user, amount="8.00")
        self.authenticate(self.user)

        response = self.client.get("/api/v1/transactions/")

        self.assertEqual(response.status_code, 200)
        body = response.json()
        self.assertIn("data", body)
        self.assertIn("pagination", body)
        self.assertEqual([item["id"] for item in body["data"]], [str(included.id)])

    def test_list_transactions_status_confirmed_returns_only_confirmed_rows(self):
        confirmed = self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            is_confirmed=True,
        )
        self.create_transaction(
            payer=self.user,
            receiver=self.third_user,
            is_confirmed=False,
            is_disputed=False,
        )
        self.authenticate(self.user)

        response = self.client.get("/api/v1/transactions/?status=confirmed")

        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["id"] for item in response.json()["data"]], [str(confirmed.id)])

    def test_list_transactions_status_pending_returns_only_pending_rows(self):
        pending = self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            is_confirmed=False,
            is_disputed=False,
        )
        self.create_transaction(
            payer=self.user,
            receiver=self.third_user,
            is_confirmed=True,
        )
        self.create_transaction(
            payer=self.third_user,
            receiver=self.user,
            is_disputed=True,
        )
        self.authenticate(self.user)

        response = self.client.get("/api/v1/transactions/?status=pending")

        self.assertEqual(response.status_code, 200)
        self.assertEqual([item["id"] for item in response.json()["data"]], [str(pending.id)])

    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_patch_confirm_as_receiver_returns_200_and_marks_confirmed(
        self,
        mock_recalculate_delay,
        mock_email_delay,
    ):
        transaction = self.create_transaction(payer=self.user, receiver=self.member_user)
        self.authenticate(self.member_user)

        with self.captureOnCommitCallbacks(execute=True):
            response = self.client.patch(f"/api/v1/transactions/{transaction.id}/confirm/")

        transaction.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["data"]["is_confirmed"])
        self.assertTrue(transaction.is_confirmed)
        self.assertEqual(mock_recalculate_delay.call_args.args, (str(self.group.id),))
        self.assertEqual(
            mock_email_delay.call_args.args,
            (str(self.user.id), str(self.member_user.id), str(transaction.id)),
        )

    def test_patch_confirm_as_payer_returns_403(self):
        transaction = self.create_transaction(payer=self.user, receiver=self.member_user)
        self.authenticate(self.user)

        response = self.client.patch(f"/api/v1/transactions/{transaction.id}/confirm/")

        self.assertEqual(response.status_code, 403)
        self.assertEqual(response.json()["detail"], "Only the receiver can confirm this transaction.")

    def test_patch_confirm_already_confirmed_returns_400(self):
        transaction = self.create_transaction(is_confirmed=True)
        self.authenticate(self.member_user)

        response = self.client.patch(f"/api/v1/transactions/{transaction.id}/confirm/")

        self.assertEqual(response.status_code, 400)
        self.assertEqual(response.json()["detail"], "Transaction is already confirmed.")

    def test_patch_dispute_as_receiver_returns_200_and_creates_audit_log(self):
        transaction = self.create_transaction(payer=self.user, receiver=self.member_user)
        self.authenticate(self.member_user)

        response = self.client.patch(f"/api/v1/transactions/{transaction.id}/dispute/")

        transaction.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertTrue(response.json()["data"]["is_disputed"])
        self.assertTrue(transaction.is_disputed)
        self.assertTrue(
            AuditLog.objects.filter(
                target_id=transaction.id,
                action="TRANSACTION_DISPUTED",
            ).exists()
        )

    def test_patch_dispute_as_payer_returns_403(self):
        transaction = self.create_transaction(payer=self.user, receiver=self.member_user)
        self.authenticate(self.user)

        response = self.client.patch(f"/api/v1/transactions/{transaction.id}/dispute/")

        self.assertEqual(response.status_code, 403)
        self.assertEqual(response.json()["detail"], "Only the receiver can dispute this transaction.")

    def test_get_transaction_detail_as_third_party_returns_403(self):
        transaction = self.create_transaction(payer=self.user, receiver=self.member_user)
        self.authenticate(self.other_user)

        response = self.client.get(f"/api/v1/transactions/{transaction.id}/")

        self.assertEqual(response.status_code, 403)
        self.assertEqual(response.json()["detail"], "You are not involved in this transaction.")

    @override_settings(ROOT_URLCONF="apps.ledger.urls")
    def test_activity_feed_includes_confirmed_transaction_items(self):
        transaction = self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            is_confirmed=True,
            note="Partial settlement",
        )
        self.authenticate(self.member_user)

        response = self.client.get(f"/groups/{self.group.id}/activity/")

        self.assertEqual(response.status_code, 200)
        activities = response.json()["data"]["activities"]
        self.assertEqual(len(activities), 1)
        self.assertEqual(activities[0]["type"], "transaction")
        self.assertEqual(activities[0]["id"], str(transaction.id))
        self.assertEqual(activities[0]["payer_id"], str(self.user.id))
        self.assertEqual(activities[0]["receiver_id"], str(self.member_user.id))
        self.assertTrue(activities[0]["is_confirmed"])
