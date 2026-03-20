from django.test import TestCase, override_settings

from apps.expenses.models import Expense
from apps.groups.models import GroupRole
from apps.splits.models import Split
from apps.transactions.models import Transaction
from apps.groups.tests.base import GroupTestMixin


@override_settings(ROOT_URLCONF="apps.ledger.urls")
class LedgerViewTests(GroupTestMixin, TestCase):
    def setUp(self):
        super().setUp()
        self.group = self.create_group()
        self.add_membership(self.group, self.user, GroupRole.ADMIN)
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        self.add_membership(self.group, self.viewer_user, GroupRole.VIEWER)

    def _balances_url(self):
        return f"/groups/{self.group.id}/balances/"

    def _simplified_url(self):
        return f"/groups/{self.group.id}/balances/simplified/"

    def _activity_url(self):
        return f"/groups/{self.group.id}/activity/"

    def _create_shared_expense(self):
        expense = Expense.objects.create(
            group=self.group,
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
        return expense

    def test_get_balances_returns_data_envelope_for_member(self):
        self._create_shared_expense()
        self.authenticate(self.member_user)

        response = self.client.get(self._balances_url())

        self.assertEqual(response.status_code, 200)
        payload = response.json()["data"]
        self.assertIn("balances", payload)
        self.assertEqual(len(payload["balances"]), 3)
        balances = {item["user_id"]: item for item in payload["balances"]}
        self.assertEqual(balances[str(self.user.id)]["user_name"], self.user.display_name)
        self.assertEqual(balances[str(self.user.id)]["balance"], "30.00")
        self.assertEqual(balances[str(self.member_user.id)]["balance"], "-30.00")
        self.assertEqual(balances[str(self.viewer_user.id)]["balance"], "0.00")

    def test_get_simplified_balances_returns_data_envelope(self):
        self._create_shared_expense()
        self.authenticate(self.member_user)

        response = self.client.get(self._simplified_url())

        self.assertEqual(response.status_code, 200)
        payload = response.json()["data"]
        self.assertTrue(payload["simplify_debts"])
        self.assertEqual(
            payload["suggestions"],
            [
                {
                    "payer_id": str(self.member_user.id),
                    "payer_name": self.member_user.display_name,
                    "receiver_id": str(self.user.id),
                    "receiver_name": self.user.display_name,
                    "amount": "30.00",
                    "currency": "BRL",
                }
            ],
        )

    def test_get_simplified_balances_returns_empty_list_when_disabled(self):
        self.group.simplify_debts = False
        self.group.save(update_fields=["simplify_debts"])
        self.authenticate(self.member_user)

        response = self.client.get(self._simplified_url())

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            response.json()["data"],
            {
                "simplify_debts": False,
                "suggestions": [],
            },
        )

    def test_get_activity_returns_group_activity_items(self):
        expense = self._create_shared_expense()
        transaction = Transaction.objects.create(
            group=self.group,
            payer=self.member_user,
            receiver=self.user,
            amount="15.00",
            currency="BRL",
            note="Partial settlement",
            is_confirmed=True,
        )
        self.authenticate(self.member_user)

        response = self.client.get(self._activity_url())

        self.assertEqual(response.status_code, 200)
        payload = response.json()["data"]
        self.assertIn("activities", payload)
        self.assertEqual(len(payload["activities"]), 2)
        activities = {item["type"]: item for item in payload["activities"]}

        expense_item = activities["expense"]
        self.assertEqual(expense_item["id"], str(expense.id))
        self.assertEqual(expense_item["group_id"], str(self.group.id))
        self.assertEqual(expense_item["description"], "Groceries")
        self.assertEqual(expense_item["paid_by_id"], str(self.user.id))
        self.assertEqual(expense_item["paid_by_name"], self.user.display_name)

        transaction_item = activities["transaction"]
        self.assertEqual(transaction_item["id"], str(transaction.id))
        self.assertEqual(transaction_item["group_id"], str(self.group.id))
        self.assertEqual(transaction_item["payer_id"], str(self.member_user.id))
        self.assertEqual(transaction_item["receiver_id"], str(self.user.id))
        self.assertEqual(transaction_item["note"], "Partial settlement")
        self.assertTrue(transaction_item["is_confirmed"])

    def test_viewer_can_access_all_read_only_ledger_endpoints(self):
        self._create_shared_expense()
        self.authenticate(self.viewer_user)

        balances_response = self.client.get(self._balances_url())
        simplified_response = self.client.get(self._simplified_url())
        activity_response = self.client.get(self._activity_url())

        self.assertEqual(balances_response.status_code, 200)
        self.assertEqual(simplified_response.status_code, 200)
        self.assertEqual(activity_response.status_code, 200)

    def test_non_member_gets_forbidden_on_all_ledger_endpoints(self):
        self.authenticate(self.other_user)

        balances_response = self.client.get(self._balances_url())
        simplified_response = self.client.get(self._simplified_url())
        activity_response = self.client.get(self._activity_url())

        self.assertEqual(balances_response.status_code, 403)
        self.assertEqual(simplified_response.status_code, 403)
        self.assertEqual(activity_response.status_code, 403)
        self.assertEqual(balances_response.json()["detail"], "You must be a member of this group.")

    def test_deleted_group_returns_404(self):
        self.group.soft_delete()
        self.authenticate(self.member_user)

        response = self.client.get(self._balances_url())

        self.assertEqual(response.status_code, 404)
