from decimal import Decimal

from django.test import TestCase

from apps.ledger.algorithms import run_min_cash_flow


class LedgerAlgorithmTests(TestCase):
    def test_simple_two_user_settlement_returns_one_transaction(self):
        suggestions = run_min_cash_flow(
            {
                "a": Decimal("100.00"),
                "b": Decimal("-100.00"),
            }
        )

        self.assertEqual(
            suggestions,
            [
                {
                    "payer_id": "b",
                    "receiver_id": "a",
                    "amount": Decimal("100.00"),
                }
            ],
        )

    def test_three_user_cycle_returns_two_transactions(self):
        suggestions = run_min_cash_flow(
            {
                "a": Decimal("250.00"),
                "b": Decimal("-125.00"),
                "c": Decimal("-125.00"),
            }
        )

        self.assertEqual(
            suggestions,
            [
                {
                    "payer_id": "b",
                    "receiver_id": "a",
                    "amount": Decimal("125.00"),
                },
                {
                    "payer_id": "c",
                    "receiver_id": "a",
                    "amount": Decimal("125.00"),
                },
            ],
        )
        self.assertEqual(len(suggestions), 2)
        self.assertEqual(sum(item["amount"] for item in suggestions), Decimal("250.00"))

    def test_already_balanced_returns_empty_list(self):
        suggestions = run_min_cash_flow(
            {
                "a": Decimal("0.00"),
                "b": Decimal("0.00"),
            }
        )

        self.assertEqual(suggestions, [])

    def test_threshold_values_are_ignored(self):
        suggestions = run_min_cash_flow(
            {
                "a": Decimal("0.005"),
                "b": Decimal("-0.004"),
                "c": Decimal("-0.001"),
            }
        )

        self.assertEqual(suggestions, [])