import uuid
from datetime import date
from decimal import Decimal
from unittest.mock import patch

from django.test import TestCase

from apps.expenses.models import Expense, SplitMethod
from apps.expenses.services import ExpenseService, ReceiptService
from core.models import AuditLog

from .base import ExpenseTestMixin


class ExpenseServiceTests(ExpenseTestMixin, TestCase):
    def test_batch_update_updates_multiple_expenses_and_reports_missing_items(self):
        first_expense = self.create_expense(group=self.group, category="geral", description="Taxi")
        second_expense = self.create_expense(group=self.group, category="geral", description="Lunch")
        missing_id = uuid.uuid4()

        result = ExpenseService.batch_update(
            [
                {
                    "id": first_expense.id,
                    "category": "transporte",
                },
                {
                    "id": second_expense.id,
                    "expense_date": date(2026, 3, 10),
                },
                {
                    "id": missing_id,
                    "category": "lazer",
                },
            ],
            self.user,
        )

        first_expense.refresh_from_db()
        second_expense.refresh_from_db()

        self.assertEqual(result["updated"], 2)
        self.assertEqual(result["errors"], [{"id": str(missing_id), "error": "Not found"}])
        self.assertEqual(first_expense.category, "transporte")
        self.assertEqual(second_expense.expense_date, date(2026, 3, 10))

    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_restore_clears_soft_deleted_fields_and_writes_audit_log(self, mock_delay):
        expense = self.create_expense(group=self.group, description="Restaurant")

        with self.captureOnCommitCallbacks(execute=True):
            ExpenseService.soft_delete(expense, self.user)

        deleted_expense = expense.__class__.all_objects.get(id=expense.id)
        self.assertTrue(deleted_expense.is_deleted)
        self.assertIsNotNone(deleted_expense.deleted_at)
        self.assertEqual(mock_delay.call_count, 1)

        mock_delay.reset_mock()

        with self.captureOnCommitCallbacks(execute=True):
            restored_expense = ExpenseService.restore(deleted_expense, self.user)

        restored_expense.refresh_from_db()

        self.assertFalse(restored_expense.is_deleted)
        self.assertIsNone(restored_expense.deleted_at)
        self.assertEqual(mock_delay.call_count, 1)
        self.assertEqual(mock_delay.call_args.args, (str(self.group.id),))
        self.assertEqual(
            list(
                AuditLog.objects.filter(target_id=expense.id)
                .order_by("created_at")
                .values_list("action", flat=True)
            ),
            ["EXPENSE_DELETED", "EXPENSE_RESTORED"],
        )

    @patch("tasks.s3_tasks.s3_confirm_upload.delay")
    def test_confirm_upload_appends_receipt_key_and_schedules_confirmation(self, mock_delay):
        expense = self.create_expense(group=self.group, description="Pharmacy")
        file_key = f"receipts/{expense.id}/receipt.png"

        with self.captureOnCommitCallbacks(execute=True):
            ReceiptService.confirm_upload(expense, file_key, self.user)

        expense.refresh_from_db()

        self.assertEqual(expense.receipt_urls, [file_key])
        self.assertEqual(mock_delay.call_count, 1)
        self.assertEqual(mock_delay.call_args.args, (file_key,))
        self.assertTrue(
            AuditLog.objects.filter(target_id=expense.id, action="RECEIPT_ADDED").exists()
        )

    @patch("tasks.notification_tasks.send_expense_created_push.delay")
    @patch("tasks.email_tasks.send_expense_notification.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_create_schedules_email_and_push_for_each_split_user(
        self,
        mock_ledger,
        mock_email,
        mock_push,
    ):
        validated = {
            "group": self.group,
            "paid_by": self.user,
            "amount": Decimal("30.00"),
            "currency": "BRL",
            "description": "Coffee",
            "category": "geral",
            "split_method": SplitMethod.EQUAL,
            "splits": [
                {"user_id": str(self.user.id), "share_value": "1"},
                {"user_id": str(self.member_user.id), "share_value": "1"},
            ],
        }

        with self.captureOnCommitCallbacks(execute=True):
            expense = ExpenseService.create(self.user, validated)

        self.assertIsInstance(expense, Expense)
        self.assertEqual(mock_email.call_count, 2)
        self.assertEqual(mock_push.call_count, 2)
        user_ids_emailed = {c.args[0] for c in mock_email.call_args_list}
        user_ids_pushed = {c.args[0] for c in mock_push.call_args_list}
        self.assertEqual(user_ids_emailed, user_ids_pushed)
        self.assertEqual(
            user_ids_emailed,
            {str(self.user.id), str(self.member_user.id)},
        )
        exp_id = str(expense.id)
        for c in mock_email.call_args_list:
            self.assertEqual(c.args[1], exp_id)
        for c in mock_push.call_args_list:
            self.assertEqual(c.args[1], exp_id)

    @patch("tasks.notification_tasks.send_expense_created_push.delay")
    @patch("tasks.email_tasks.send_expense_notification.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay", side_effect=ConnectionError("broker down"))
    def test_create_persists_expense_even_if_broker_is_unreachable(
        self,
        mock_ledger,
        mock_email,
        mock_push,
    ):
        """A committed expense must not surface as a request failure just
        because the post-commit Celery enqueue can't reach the broker."""
        validated = {
            "group": self.group,
            "paid_by": self.user,
            "amount": Decimal("30.00"),
            "currency": "BRL",
            "description": "Coffee",
            "category": "geral",
            "split_method": SplitMethod.EQUAL,
            "splits": [
                {"user_id": str(self.user.id), "share_value": "1"},
                {"user_id": str(self.member_user.id), "share_value": "1"},
            ],
        }

        with self.captureOnCommitCallbacks(execute=True):
            expense = ExpenseService.create(self.user, validated)

        self.assertTrue(Expense.objects.filter(id=expense.id).exists())
