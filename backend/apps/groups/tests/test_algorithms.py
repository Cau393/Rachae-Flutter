from decimal import Decimal

from django.test import SimpleTestCase

from apps.groups.algorithms import run_min_cash_flow


class GroupAlgorithmTests(SimpleTestCase):
    def test_three_person_cycle_resolves_to_two_transactions(self):
        suggestions = run_min_cash_flow(
            {
                "user-a": Decimal("10.00"),
                "user-b": Decimal("5.00"),
                "user-c": Decimal("-15.00"),
            }
        )

        self.assertEqual(len(suggestions), 2)
        self.assertEqual(sum(item["amount"] for item in suggestions), Decimal("15.00"))

    def test_single_debtor_and_creditor_resolves_to_one_transaction(self):
        suggestions = run_min_cash_flow(
            {
                "creditor": Decimal("20.00"),
                "debtor": Decimal("-20.00"),
            }
        )

        self.assertEqual(
            suggestions,
            [
                {
                    "payer_id": "debtor",
                    "receiver_id": "creditor",
                    "amount": Decimal("20.00"),
                }
            ],
        )

    def test_balanced_group_returns_empty_list(self):
        suggestions = run_min_cash_flow(
            {
                "user-a": Decimal("0.00"),
                "user-b": Decimal("0.00"),
            }
        )

        self.assertEqual(suggestions, [])

    def test_transfers_conserve_total_positive_balance(self):
        balances = {
            "user-a": Decimal("25.00"),
            "user-b": Decimal("5.00"),
            "user-c": Decimal("-10.00"),
            "user-d": Decimal("-20.00"),
        }

        suggestions = run_min_cash_flow(balances)
        positive_total = sum(amount for amount in balances.values() if amount > 0)

        self.assertEqual(sum(item["amount"] for item in suggestions), positive_total)
