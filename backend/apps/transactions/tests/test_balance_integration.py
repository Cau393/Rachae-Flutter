from decimal import Decimal
from unittest.mock import patch

from django.core.cache import cache
from django.test import TestCase, override_settings

from apps.ledger.algorithms import compute_group_net_balances
from apps.transactions.services import TransactionService

from .test_services import TransactionTestMixin


class TransactionBalanceIntegrationTests(TransactionTestMixin, TestCase):
    def setUp(self):
        super().setUp()
        cache.clear()

    def tearDown(self):
        cache.clear()
        super().tearDown()

    def _create_shared_expense(self):
        expense = self.create_expense(
            group=self.group,
            paid_by=self.user,
            amount="60.00",
            amount_in_group_currency="60.00",
        )
        self.create_split(expense, self.user, "30.00")
        self.create_split(expense, self.member_user, "30.00")
        return expense

    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_confirmed_transaction_is_reflected_in_compute_group_net_balances(
        self,
        mock_recalculate_delay,
        mock_email_delay,
    ):
        self._create_shared_expense()
        transaction = self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            amount="10.00",
        )

        with self.captureOnCommitCallbacks(execute=True):
            TransactionService.confirm(transaction, self.member_user)

        balances = compute_group_net_balances(str(self.group.id))

        self.assertEqual(balances[str(self.user.id)], Decimal("40.00"))
        self.assertEqual(balances[str(self.member_user.id)], Decimal("-40.00"))
        self.assertEqual(mock_recalculate_delay.call_args.args, (str(self.group.id),))
        self.assertEqual(
            mock_email_delay.call_args.args,
            (str(self.user.id), str(self.member_user.id), str(transaction.id)),
        )

    def test_pending_non_disputed_transaction_changes_compute_group_net_balances(self):
        self._create_shared_expense()
        self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            amount="10.00",
            is_confirmed=False,
        )

        balances = compute_group_net_balances(str(self.group.id))

        self.assertEqual(balances[str(self.user.id)], Decimal("40.00"))
        self.assertEqual(balances[str(self.member_user.id)], Decimal("-40.00"))

    def test_disputed_unconfirmed_transaction_does_not_change_compute_group_net_balances(self):
        self._create_shared_expense()
        self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            amount="10.00",
            is_confirmed=False,
            is_disputed=True,
        )

        balances = compute_group_net_balances(str(self.group.id))

        self.assertEqual(balances[str(self.user.id)], Decimal("30.00"))
        self.assertEqual(balances[str(self.member_user.id)], Decimal("-30.00"))

    @override_settings(ROOT_URLCONF="apps.ledger.urls")
    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_group_balances_endpoint_reflects_reduced_debt_after_confirmed_settlement(
        self,
        mock_recalculate_delay,
        mock_email_delay,
    ):
        self._create_shared_expense()
        transaction = self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            amount="10.00",
        )
        with self.captureOnCommitCallbacks(execute=True):
            TransactionService.confirm(transaction, self.member_user)

        self.authenticate(self.member_user)
        response = self.client.get(f"/groups/{self.group.id}/balances/")

        self.assertEqual(response.status_code, 200)
        balances = {item["user_id"]: item["balance"] for item in response.json()["data"]["balances"]}
        self.assertEqual(balances[str(self.user.id)], "40.00")
        self.assertEqual(balances[str(self.member_user.id)], "-40.00")
        self.assertEqual(mock_recalculate_delay.call_args.args, (str(self.group.id),))
        self.assertEqual(
            mock_email_delay.call_args.args,
            (str(self.user.id), str(self.member_user.id), str(transaction.id)),
        )

    def test_user_balance_endpoint_reflects_pending_non_disputed_settlement(self):
        self._create_shared_expense()
        self.create_transaction(
            payer=self.member_user,
            receiver=self.user,
            amount="10.00",
            is_confirmed=False,
        )

        self.authenticate(self.user)
        response = self.client.get(f"/api/v1/users/{self.member_user.id}/balances/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"balance": "20.00", "currency": "BRL"})

    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_user_balance_endpoint_reflects_confirmed_transactions_between_two_users(
        self,
        mock_recalculate_delay,
        mock_email_delay,
    ):
        self._create_shared_expense()
        transaction = self.create_transaction(
            payer=self.member_user,
            receiver=self.user,
            amount="10.00",
        )
        with self.captureOnCommitCallbacks(execute=True):
            TransactionService.confirm(transaction, self.user)

        self.authenticate(self.user)
        response = self.client.get(f"/api/v1/users/{self.member_user.id}/balances/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"balance": "20.00", "currency": "BRL"})
        self.assertEqual(mock_recalculate_delay.call_args.args, (str(self.group.id),))
        self.assertEqual(
            mock_email_delay.call_args.args,
            (str(self.member_user.id), str(self.user.id), str(transaction.id)),
        )

    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_user_balance_endpoint_reduces_debt_after_debtor_pays_creditor(
        self,
        mock_recalculate_delay,
        mock_email_delay,
    ):
        self.make_user_owes_member(owed="20.00")
        transaction = self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            amount="10.00",
        )
        with self.captureOnCommitCallbacks(execute=True):
            TransactionService.confirm(transaction, self.member_user)

        self.authenticate(self.user)
        response = self.client.get(f"/api/v1/users/{self.member_user.id}/balances/")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json(), {"balance": "-10.00", "currency": "BRL"})
        self.assertEqual(mock_recalculate_delay.call_args.args, (str(self.group.id),))
        self.assertEqual(
            mock_email_delay.call_args.args,
            (str(self.user.id), str(self.member_user.id), str(transaction.id)),
        )

    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_group_balances_endpoint_uses_settlement_aware_math_in_default_urls(
        self,
        mock_recalculate_delay,
        mock_email_delay,
    ):
        self._create_shared_expense()
        transaction = self.create_transaction(
            payer=self.user,
            receiver=self.member_user,
            amount="10.00",
        )
        with self.captureOnCommitCallbacks(execute=True):
            TransactionService.confirm(transaction, self.member_user)

        self.authenticate(self.member_user)
        response = self.client.get(f"/api/v1/groups/{self.group.id}/balances/")

        self.assertEqual(response.status_code, 200)
        balances = {item["user_id"]: item["net_balance"] for item in response.json()["balances"]}
        self.assertEqual(balances[str(self.user.id)], "40.00")
        self.assertEqual(balances[str(self.member_user.id)], "-40.00")
        self.assertEqual(mock_recalculate_delay.call_args.args, (str(self.group.id),))
        self.assertEqual(
            mock_email_delay.call_args.args,
            (str(self.user.id), str(self.member_user.id), str(transaction.id)),
        )
