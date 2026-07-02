from decimal import Decimal
from unittest.mock import patch

from django.test import TestCase, override_settings

from apps.expenses.models import Expense, SplitMethod
from apps.transactions.models import Transaction
from apps.transactions.settlement_splits import apply_confirmed_group_settlement_to_splits
from core.models import AuditLog

from .base import ExpenseTestMixin


class ExpenseViewTests(ExpenseTestMixin, TestCase):
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_delete_endpoint_soft_deletes_expense(self, mock_delay):
        expense = self.create_expense(group=self.group, description="Utilities")
        self.create_split(expense, self.user, "30.00")
        self.create_split(expense, self.member_user, "30.00")
        self.authenticate(self.user)

        with self.captureOnCommitCallbacks(execute=True):
            response = self.client.delete(f"/api/v1/expenses/{expense.id}/")

        deleted_expense = Expense.all_objects.get(id=expense.id)

        self.assertEqual(response.status_code, 204)
        self.assertTrue(deleted_expense.is_deleted)
        self.assertTrue(
            AuditLog.objects.filter(target_id=expense.id, action="EXPENSE_DELETED").exists()
        )
        self.assertEqual(mock_delay.call_args.args, (str(self.group.id),))

    def test_split_participant_can_view_detail_but_uninvolved_user_gets_forbidden(self):
        expense = self.create_expense(group=None, description="Dinner")
        self.create_split(expense, self.user, "25.00")
        self.create_split(expense, self.other_user, "25.00")

        self.authenticate(self.other_user)
        allowed_response = self.client.get(f"/api/v1/expenses/{expense.id}/")

        self.authenticate(self.third_user)
        denied_response = self.client.get(f"/api/v1/expenses/{expense.id}/")

        self.assertEqual(allowed_response.status_code, 200)
        self.assertEqual(allowed_response.json()["data"]["id"], str(expense.id))
        self.assertEqual(denied_response.status_code, 403)
        self.assertEqual(
            denied_response.json()["detail"],
            "You are not involved in this expense.",
        )

    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_restore_endpoint_restores_deleted_expense(self, mock_delay):
        expense = self.create_expense(group=self.group, description="Hotel")
        expense.soft_delete()
        self.authenticate(self.user)

        with self.captureOnCommitCallbacks(execute=True):
            response = self.client.post(f"/api/v1/expenses/{expense.id}/restore/")

        expense.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertFalse(expense.is_deleted)
        self.assertIsNone(expense.deleted_at)
        self.assertEqual(response.json()["data"]["id"], str(expense.id))
        self.assertEqual(mock_delay.call_args.args, (str(self.group.id),))

    @override_settings(CLOUDFRONT_DOMAIN="cdn.example.com")
    @patch("tasks.s3_tasks.s3_confirm_upload.delay")
    def test_receipt_confirm_endpoint_stores_key_and_returns_cloudfront_url(self, mock_delay):
        expense = self.create_expense(group=self.group, description="Receipt")
        file_key = f"receipts/{expense.id}/receipt.png"
        self.authenticate(self.user)

        with self.captureOnCommitCallbacks(execute=True):
            response = self.client.patch(
                f"/api/v1/expenses/{expense.id}/receipts/confirm/",
                data={"file_key": file_key},
                format="json",
            )

        expense.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(expense.receipt_urls, [file_key])
        self.assertEqual(
            response.json()["data"]["receipt_urls"],
            [f"https://cdn.example.com/{file_key}"],
        )
        self.assertEqual(mock_delay.call_args.args, (file_key,))

    def test_batch_update_endpoint_updates_multiple_expenses(self):
        first_expense = self.create_expense(group=self.group, category="geral", description="Bus")
        second_expense = self.create_expense(group=self.group, category="geral", description="Movie")
        self.authenticate(self.user)

        response = self.client.put(
            "/api/v1/expenses/batch/",
            data={
                "updates": [
                    {"id": str(first_expense.id), "category": "transporte"},
                    {"id": str(second_expense.id), "category": "lazer"},
                ]
            },
            format="json",
        )

        first_expense.refresh_from_db()
        second_expense.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["updated"], 2)
        self.assertEqual(response.json()["data"]["errors"], [])
        self.assertEqual(first_expense.category, "transporte")
        self.assertEqual(second_expense.category, "lazer")

    def test_list_expenses_returns_paginated_results(self):
        self.create_expense(group=self.group)
        self.create_expense(group=self.group)

        self.authenticate(self.user)

        response = self.client.get("/api/v1/expenses/")

        self.assertEqual(response.status_code, 200)
        body = response.json()

        self.assertIn("data", body)
        self.assertIn("pagination", body)
        self.assertEqual(len(body["data"]), 2)

    def test_list_expenses_owed_to_me_includes_shared_expenses_paid_by_user(self):
        """Payer has a split row; filter must still return expenses others owe on."""
        shared = self.create_expense(
            group=self.group,
            paid_by=self.user,
            description="Dinner split",
        )
        self.create_split(shared, self.user, "25.00")
        self.create_split(shared, self.member_user, "25.00")

        solo = self.create_expense(
            group=self.group,
            paid_by=self.user,
            description="Solo note",
        )
        self.create_split(solo, self.user, "50.00")

        self.authenticate(self.user)

        response = self.client.get("/api/v1/expenses/?owed_to_me=true")

        self.assertEqual(response.status_code, 200)
        ids = {item["id"] for item in response.json()["data"]}
        self.assertIn(str(shared.id), ids)
        self.assertNotIn(str(solo.id), ids)

    def test_list_expenses_owed_to_me_empty_after_counterparty_fully_settled(self):
        shared = self.create_expense(
            group=self.group,
            paid_by=self.user,
            description="Lunch",
            amount="50.00",
            amount_in_group_currency="50.00",
        )
        self.create_split(shared, self.user, "25.00")
        self.create_split(shared, self.member_user, "25.00")

        self.authenticate(self.user)
        self.assertEqual(
            len(self.client.get("/api/v1/expenses/?owed_to_me=true").json()["data"]),
            1,
        )

        txn = Transaction.objects.create(
            group=self.group,
            payer=self.member_user,
            receiver=self.user,
            amount="25.00",
            currency="BRL",
            is_confirmed=True,
        )
        apply_confirmed_group_settlement_to_splits(txn)

        response = self.client.get("/api/v1/expenses/?owed_to_me=true")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"], [])

    def test_list_expenses_owed_to_me_empty_after_non_group_settlement(self):
        shared = self.create_expense(
            group=None,
            paid_by=self.user,
            description="Personal lunch",
            amount="50.00",
            amount_in_group_currency="50.00",
        )
        self.create_split(shared, self.user, "25.00")
        self.create_split(shared, self.member_user, "25.00")

        self.authenticate(self.user)
        self.assertEqual(
            len(self.client.get("/api/v1/expenses/?owed_to_me=true").json()["data"]),
            1,
        )

        txn = Transaction.objects.create(
            group=None,
            payer=self.member_user,
            receiver=self.user,
            amount="25.00",
            currency="BRL",
            is_confirmed=True,
        )
        apply_confirmed_group_settlement_to_splits(txn)

        response = self.client.get("/api/v1/expenses/?owed_to_me=true")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"], [])

    def test_list_expenses_owed_to_me_only_first_expense_after_one_payment_covers_fifo(
        self,
    ):
        """One confirmed payment applies FIFO to the oldest expense first (nominal replay)."""
        first = self.create_expense(
            group=None,
            paid_by=self.user,
            description="Older",
            amount="20.00",
            amount_in_group_currency="20.00",
        )
        self.create_split(first, self.user, "10.00")
        self.create_split(first, self.member_user, "10.00")
        second = self.create_expense(
            group=None,
            paid_by=self.user,
            description="Newer",
            amount="20.00",
            amount_in_group_currency="20.00",
        )
        self.create_split(second, self.user, "10.00")
        self.create_split(second, self.member_user, "10.00")

        txn = Transaction.objects.create(
            group=None,
            payer=self.member_user,
            receiver=self.user,
            amount="10.00",
            currency="BRL",
            is_confirmed=True,
        )
        apply_confirmed_group_settlement_to_splits(txn)

        self.authenticate(self.user)
        response = self.client.get("/api/v1/expenses/?owed_to_me=true")
        self.assertEqual(response.status_code, 200)
        ids = {item["id"] for item in response.json()["data"]}
        self.assertEqual(ids, {str(second.id)})

    def test_list_expenses_owed_to_me_empty_when_net_pairwise_zero_from_offsetting_expenses(
        self,
    ):
        """Member still has unsettled split on user's expense but user owes member same net elsewhere."""
        user_paid = self.create_expense(
            group=None,
            paid_by=self.user,
            description="I paid dinner",
            amount="20.00",
            amount_in_group_currency="20.00",
        )
        self.create_split(user_paid, self.user, "10.00")
        self.create_split(user_paid, self.member_user, "10.00")

        member_paid = self.create_expense(
            group=None,
            paid_by=self.member_user,
            created_by=self.member_user,
            description="Member paid taxi",
            amount="20.00",
            amount_in_group_currency="20.00",
        )
        self.create_split(member_paid, self.member_user, "10.00")
        self.create_split(member_paid, self.user, "10.00")

        self.authenticate(self.user)
        response = self.client.get("/api/v1/expenses/?owed_to_me=true")
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"], [])

    def test_list_expenses_with_user_returns_only_pairwise_expenses(self):
        shared = self.create_expense(group=None, paid_by=self.user, description="Shared lunch")
        self.create_split(shared, self.member_user, "15.00")

        unrelated = self.create_expense(group=None, paid_by=self.user, description="Shared taxi")
        self.create_split(unrelated, self.third_user, "10.00")

        reverse_shared = self.create_expense(
            group=None,
            paid_by=self.member_user,
            created_by=self.member_user,
            description="Coffee",
        )
        self.create_split(reverse_shared, self.user, "8.00")

        self.authenticate(self.user)

        response = self.client.get(f"/api/v1/expenses/?with_user={self.member_user.id}")

        self.assertEqual(response.status_code, 200)
        self.assertEqual(
            [item["id"] for item in response.json()["data"]],
            [str(reverse_shared.id), str(shared.id)],
        )
    
    @patch("apps.expenses.serializers.get_exchange_rate")
    def test_create_expense_endpoint_creates_expense(self, mock_rate):
        mock_rate.return_value = Decimal("1.0")
        self.group.currency = "BRL"
        self.group.save()
        
        self.authenticate(self.user)

        payload = {
            "group_id": str(self.group.id),
            "paid_by": str(self.user.id),
            "description": "lol",
            "amount": "50.00",
            "splits": [
                {"user_id": str(self.user.id), "amount_owed": "25.00"},
                {"user_id": str(self.member_user.id), "amount_owed": "25.00"},
            ],
        }

        response = self.client.post(
            "/api/v1/expenses/",
            data=payload,
            format="json",
        )

        self.assertEqual(response.status_code, 201)

        expense = Expense.objects.get(description="lol")

        # Core fields
        self.assertEqual(expense.group, self.group)
        self.assertEqual(expense.paid_by, self.user)
        self.assertEqual(expense.created_by, self.user)
        self.assertEqual(expense.amount, Decimal("50.00"))

        # Defaults
        self.assertEqual(expense.currency, "BRL")
        self.assertEqual(expense.category, "geral")
        self.assertEqual(expense.split_method, SplitMethod.EQUAL)

        # Splits created
        splits = expense.splits.all()
        self.assertEqual(splits.count(), 2)

        amounts = sorted([s.amount_owed for s in splits])
        self.assertEqual(amounts, [Decimal("25.00"), Decimal("25.00")])

        # Response contract
        body = response.json()
        self.assertEqual(body["data"]["id"], str(expense.id))
    
    def test_put_updates_entire_expense(self):
        expense = self.create_expense(
            group=self.group,
            description="Antiga",
            amount="50.00",
            paid_by=self.user,
        )

        self.create_split(expense, self.user, "25.00")
        self.create_split(expense, self.member_user, "25.00")

        self.authenticate(self.user)

        response = self.client.put(
            f"/api/v1/expenses/{expense.id}/",
            data={
                "group_id": str(self.group.id),
                "paid_by": str(self.user.id),
                "amount": "60.00",
                "description": "New",
                "category": "comida",
                "split_method": "exact",
                "splits": [
                    {"user_id": str(self.user.id), "amount_owed": "30.00"},
                    {"user_id": str(self.member_user.id), "amount_owed": "30.00"},
                ],
            },
            format="json",
        )

        expense.refresh_from_db()

        self.assertEqual(response.status_code, 200)

        self.assertEqual(expense.description, "New")
        self.assertEqual(expense.amount, Decimal("60.00"))
        self.assertEqual(expense.category, "comida")
        self.assertEqual(expense.split_method, "exact")

        splits = expense.splits.all()
        self.assertEqual(splits.count(), 2)

        amounts = sorted([s.amount_owed for s in splits])
        self.assertEqual(amounts, [Decimal("30.00"), Decimal("30.00")])
    
    def test_patch_updates_single_field(self):
        expense = self.create_expense(group=self.group, description="Taxi")

        self.authenticate(self.user)

        response = self.client.patch(
            f"/api/v1/expenses/{expense.id}/",
            data={"description": "Uber"},
            format="json",
        )

        expense.refresh_from_db()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(expense.description, "Uber")
    
    @patch("apps.expenses.services.ReceiptService.generate_upload_url")
    def test_receipt_upload_url_endpoint_returns_url(self, mock_service):
        expense = self.create_expense(group=self.group)

        mock_service.return_value = {
            "upload_url": "https://s3.fake/upload",
            "file_key": "receipts/file.png",
        }

        self.authenticate(self.user)

        response = self.client.get(
            f"/api/v1/expenses/{expense.id}/receipt-upload-url/?content_type=image/png"
        )

        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["data"]["upload_url"], "https://s3.fake/upload")
    
    def test_receipt_delete_removes_receipt(self):
        expense = self.create_expense(group=self.group)
        expense.receipt_urls = ["receipts/test.png"]
        expense.save()

        self.authenticate(self.user)

        response = self.client.delete(
            f"/api/v1/expenses/{expense.id}/receipts/",
            data={"file_key": "receipts/test.png"},
            format="json",
        )

        expense.refresh_from_db()

        self.assertEqual(response.status_code, 204)
        self.assertEqual(expense.receipt_urls, [])
    
    def test_non_creator_cannot_update_expense(self):
        expense = self.create_expense(group=self.group)

        self.authenticate(self.third_user)

        response = self.client.patch(
            f"/api/v1/expenses/{expense.id}/",
            data={"description": "Hacked"},
            format="json",
        )

        self.assertEqual(response.status_code, 403)
    
    def test_batch_update_fails_for_non_admin(self):
        expense = self.create_expense(group=self.group)

        self.authenticate(self.member_user)

        response = self.client.put(
            "/api/v1/expenses/batch/",
            data={
                "updates": [
                    {"id": str(expense.id), "category": "comida"},
                ]
            },
            format="json",
        )

        body = response.json()

        self.assertEqual(response.status_code, 200)
        self.assertEqual(body["data"]["updated"], 0)
        self.assertEqual(len(body["data"]["errors"]), 1)
    
    def test_put_cannot_change_expense_group(self):
        other_group = self.create_group()

        expense = self.create_expense(group=self.group)

        self.create_split(expense, self.user, "25.00")
        self.create_split(expense, self.member_user, "25.00")

        self.authenticate(self.user)

        response = self.client.put(
            f"/api/v1/expenses/{expense.id}/",
            data={
                "group_id": str(other_group.id),
                "paid_by": str(self.user.id),
                "amount": "50.00",
                "description": "Invalid",
                "split_method": "exact",
                "splits": [
                    {"user": str(self.user.id), "amount": "25.00"},
                    {"user": str(self.member_user.id), "amount": "25.00"},
                ],
            },
            format="json",
        )

        self.assertEqual(response.status_code, 400)