import uuid

from django.test import TestCase
from rest_framework.test import APIClient

from apps.expenses.models import Expense
from apps.groups.models import GroupRole
from apps.groups.tests.base import GroupTestMixin
class LedgerActivityFeedTests(GroupTestMixin, TestCase):
    def setUp(self):
        super().setUp()
        self.group = self.create_group()
        self.group_b = self.create_group(name="Second Group")
        self.add_membership(self.group, self.user, GroupRole.ADMIN)
        self.add_membership(self.group_b, self.user, GroupRole.MEMBER)
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)

    def _url(self, **query):
        base = "/api/v1/ledger/activity/"
        if not query:
            return base
        q = "&".join(f"{k}={v}" for k, v in query.items())
        return f"{base}?{q}"

    def test_global_feed_requires_auth(self):
        client = APIClient()
        response = client.get(self._url())
        self.assertEqual(response.status_code, 401)

    def test_global_feed_returns_activities_from_all_member_groups(self):
        expense_a = Expense.objects.create(
            group=self.group,
            paid_by=self.user,
            amount="10.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="10.00",
            description="A",
            created_by=self.user,
        )
        expense_b = Expense.objects.create(
            group=self.group_b,
            paid_by=self.user,
            amount="20.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="20.00",
            description="B",
            created_by=self.user,
        )
        self.client.force_authenticate(user=self.user)
        response = self.client.get(self._url(page=1, limit=20))
        self.assertEqual(response.status_code, 200)
        activities = response.json()["data"]["activities"]
        ids = {a["id"] for a in activities}
        self.assertIn(str(expense_a.id), ids)
        self.assertIn(str(expense_b.id), ids)

    def test_group_filter_returns_only_that_group(self):
        expense_a = Expense.objects.create(
            group=self.group,
            paid_by=self.user,
            amount="10.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="10.00",
            description="A",
            created_by=self.user,
        )
        Expense.objects.create(
            group=self.group_b,
            paid_by=self.user,
            amount="20.00",
            currency="BRL",
            exchange_rate_to_group_currency="1.000000",
            amount_in_group_currency="20.00",
            description="B",
            created_by=self.user,
        )
        self.client.force_authenticate(user=self.user)
        response = self.client.get(
            self._url(page=1, limit=20, group_id=str(self.group.id))
        )
        self.assertEqual(response.status_code, 200)
        activities = response.json()["data"]["activities"]
        self.assertEqual(len(activities), 1)
        self.assertEqual(activities[0]["id"], str(expense_a.id))

    def test_non_member_gets_403_for_group_filter(self):
        self.client.force_authenticate(user=self.other_user)
        response = self.client.get(
            self._url(page=1, limit=20, group_id=str(self.group.id))
        )
        self.assertEqual(response.status_code, 403)

    def test_pagination_limit(self):
        for i in range(3):
            Expense.objects.create(
                group=self.group,
                paid_by=self.user,
                amount="1.00",
                currency="BRL",
                exchange_rate_to_group_currency="1.000000",
                amount_in_group_currency="1.00",
                description=f"E{i}",
                created_by=self.user,
            )
        self.client.force_authenticate(user=self.user)
        r1 = self.client.get(self._url(page=1, limit=2, group_id=str(self.group.id)))
        self.assertEqual(r1.status_code, 200)
        self.assertEqual(len(r1.json()["data"]["activities"]), 2)
        r2 = self.client.get(self._url(page=2, limit=2, group_id=str(self.group.id)))
        self.assertEqual(r2.status_code, 200)
        self.assertEqual(len(r2.json()["data"]["activities"]), 1)

    def test_invalid_group_id_returns_400(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get(self._url(page=1, group_id="not-a-uuid"))
        self.assertEqual(response.status_code, 400)

    def test_unknown_group_returns_404(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.get(
            self._url(page=1, group_id=str(uuid.uuid4()))
        )
        self.assertEqual(response.status_code, 404)
