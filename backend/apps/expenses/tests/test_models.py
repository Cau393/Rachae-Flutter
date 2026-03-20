from django.test import TestCase

from apps.expenses.models import Expense
from apps.splits.models import Split

from .base import ExpenseTestMixin


class ExpenseModelTests(ExpenseTestMixin, TestCase):
    def test_soft_delete_sets_deleted_at_and_keeps_splits(self):
        expense = self.create_expense(group=self.group, amount="42.50")
        first_split = self.create_split(expense, self.user, "21.25")
        second_split = self.create_split(expense, self.member_user, "21.25")

        expense.soft_delete()

        deleted_expense = Expense.all_objects.get(id=expense.id)

        self.assertTrue(deleted_expense.is_deleted)
        self.assertIsNotNone(deleted_expense.deleted_at)
        self.assertFalse(Expense.objects.filter(id=expense.id).exists())
        self.assertEqual(
            set(Split.objects.filter(expense=expense).values_list("id", flat=True)),
            {first_split.id, second_split.id},
        )
