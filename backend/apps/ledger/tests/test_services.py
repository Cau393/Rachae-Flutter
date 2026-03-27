from decimal import Decimal
from unittest.mock import patch

from django.core.cache import cache
from django.test import TestCase

from apps.expenses.models import Expense
from apps.groups.models import GroupRole
from apps.ledger.services import (
    GROUP_BALANCES_CACHE_KEY,
    GROUP_SIMPLIFIED_CACHE_KEY,
    LedgerService,
)
from apps.splits.models import Split
from apps.groups.tests.base import GroupTestMixin


class LedgerServiceTests(GroupTestMixin, TestCase):
    def setUp(self):
        super().setUp()
        cache.clear()

    def tearDown(self):
        cache.clear()
        super().tearDown()

    def _create_group_with_members(self, *, simplify_debts=True):
        group = self.create_group(simplify_debts=simplify_debts)
        self.add_membership(group, self.user, GroupRole.ADMIN)
        self.add_membership(group, self.member_user, GroupRole.MEMBER)
        self.add_membership(group, self.viewer_user, GroupRole.VIEWER)
        return group

    def _create_shared_expense(self, group):
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
        return expense

    def test_get_group_balances_returns_balance_for_each_active_member(self):
        group = self._create_group_with_members()
        self._create_shared_expense(group)

        payload = LedgerService.get_group_balances(group.id)

        self.assertEqual(set(payload.keys()), {"balances"})
        balances = {item["user_id"]: item for item in payload["balances"]}
        self.assertEqual(balances[str(self.user.id)]["user_name"], self.user.display_name)
        self.assertEqual(balances[str(self.user.id)]["balance"], Decimal("30.00"))
        self.assertEqual(balances[str(self.member_user.id)]["user_name"], self.member_user.display_name)
        self.assertEqual(balances[str(self.member_user.id)]["balance"], Decimal("-30.00"))

    def test_get_group_balances_uses_zero_for_member_without_activity(self):
        group = self._create_group_with_members()
        self._create_shared_expense(group)

        payload = LedgerService.get_group_balances(group.id)

        balances = {item["user_id"]: item["balance"] for item in payload["balances"]}
        self.assertEqual(balances[str(self.viewer_user.id)], Decimal("0"))

    @patch("apps.ledger.services.compute_group_net_balances")
    def test_get_group_balances_reads_from_cache_after_first_call(self, mock_compute_group_net_balances):
        group = self._create_group_with_members()
        mock_compute_group_net_balances.return_value = {
            str(self.user.id): Decimal("10.00"),
            str(self.member_user.id): Decimal("-10.00"),
            str(self.viewer_user.id): Decimal("0"),
        }

        first_payload = LedgerService.get_group_balances(group.id)
        second_payload = LedgerService.get_group_balances(group.id)

        self.assertEqual(first_payload, second_payload)
        mock_compute_group_net_balances.assert_called_once_with(str(group.id))
        cache_key = GROUP_BALANCES_CACHE_KEY.format(group_id=str(group.id))
        self.assertEqual(cache.get(cache_key), first_payload)

    @patch("apps.ledger.services.simplify_group_debts")
    def test_get_simplified_balances_returns_disabled_payload_when_group_does_not_simplify(
        self,
        mock_simplify_group_debts,
    ):
        group = self._create_group_with_members(simplify_debts=False)

        payload = LedgerService.get_simplified_balances(group)

        self.assertEqual(
            payload,
            {
                "simplify_debts": False,
                "suggestions": [],
            },
        )
        mock_simplify_group_debts.assert_not_called()

    @patch("apps.ledger.services.simplify_group_debts")
    def test_get_simplified_balances_returns_algorithm_payload_when_enabled(self, mock_simplify_group_debts):
        group = self._create_group_with_members(simplify_debts=True)
        mock_simplify_group_debts.return_value = [
            {
                "payer_id": str(self.member_user.id),
                "payer_name": self.member_user.display_name,
                "receiver_id": str(self.user.id),
                "receiver_name": self.user.display_name,
                "amount": Decimal("30.00"),
                "currency": group.currency,
            }
        ]

        payload = LedgerService.get_simplified_balances(group)

        self.assertEqual(
            payload,
            {
                "simplify_debts": True,
                "suggestions": mock_simplify_group_debts.return_value,
            },
        )
        mock_simplify_group_debts.assert_called_once_with(str(group.id), group.currency)

    @patch("apps.ledger.services.simplify_group_debts")
    def test_get_simplified_balances_reads_from_cache_after_first_call(self, mock_simplify_group_debts):
        group = self._create_group_with_members(simplify_debts=True)
        mock_simplify_group_debts.return_value = [
            {
                "payer_id": str(self.member_user.id),
                "payer_name": self.member_user.display_name,
                "receiver_id": str(self.user.id),
                "receiver_name": self.user.display_name,
                "amount": Decimal("15.00"),
                "currency": group.currency,
            }
        ]

        first_payload = LedgerService.get_simplified_balances(group)
        second_payload = LedgerService.get_simplified_balances(group)

        self.assertEqual(first_payload, second_payload)
        mock_simplify_group_debts.assert_called_once_with(str(group.id), group.currency)
        cache_key = GROUP_SIMPLIFIED_CACHE_KEY.format(group_id=str(group.id))
        self.assertEqual(cache.get(cache_key), first_payload)

    def test_get_group_balances_deserializes_task_cached_map_shape(self):
        group = self._create_group_with_members()
        cache_key = GROUP_BALANCES_CACHE_KEY.format(group_id=str(group.id))
        cache.set(
            cache_key,
            {
                str(self.user.id): "12.50",
                str(self.member_user.id): "-12.50",
            },
        )

        payload = LedgerService.get_group_balances(group.id)

        balances = {item["user_id"]: item["balance"] for item in payload["balances"]}
        self.assertEqual(balances[str(self.user.id)], Decimal("12.50"))
        self.assertEqual(balances[str(self.member_user.id)], Decimal("-12.50"))

    def test_get_simplified_balances_deserializes_task_cached_list_shape(self):
        group = self._create_group_with_members(simplify_debts=True)
        cache_key = GROUP_SIMPLIFIED_CACHE_KEY.format(group_id=str(group.id))
        cached_list = [
            {
                "payer_id": str(self.member_user.id),
                "payer_name": self.member_user.display_name,
                "receiver_id": str(self.user.id),
                "receiver_name": self.user.display_name,
                "amount": "10.00",
                "currency": group.currency,
            }
        ]
        cache.set(cache_key, cached_list)

        payload = LedgerService.get_simplified_balances(group)

        self.assertEqual(
            payload,
            {
                "simplify_debts": True,
                "suggestions": cached_list,
            },
        )
