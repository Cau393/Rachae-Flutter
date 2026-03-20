import uuid
from decimal import Decimal
from unittest.mock import patch

from django.test import TestCase
from rest_framework.exceptions import PermissionDenied
from rest_framework.test import APIClient

from apps.expenses.models import Expense, SplitMethod
from apps.groups.models import Group, GroupMember, GroupRole, GroupType
from apps.splits.models import Split
from apps.transactions.models import Transaction
from apps.transactions.services import TransactionService
from apps.users.models import User
from core.models import AuditLog


class TransactionTestMixin:
    def setUp(self):
        super().setUp()
        self.client = APIClient()
        self.user = self.create_user("owner@example.com", "+5511999999999", "Owner User")
        self.member_user = self.create_user("member@example.com", "+5511888888888", "Member User")
        self.third_user = self.create_user("third@example.com", "+5511777777777", "Third User")
        self.other_user = self.create_user("other@example.com", "+5511666666666", "Other User")

        self.group = self.create_group()
        self.add_membership(self.group, self.user, GroupRole.ADMIN)
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        self.add_membership(self.group, self.third_user, GroupRole.MEMBER)

    def create_user(self, email: str, phone: str, display_name: str) -> User:
        return User.objects.create(
            supabase_uid=uuid.uuid4(),
            email=email,
            phone=phone,
            display_name=display_name,
        )

    def create_group(
        self,
        *,
        created_by=None,
        name: str = "Trip Group",
        description: str | None = None,
        group_type: str = GroupType.TRIP,
        currency: str = "BRL",
        simplify_debts: bool = True,
    ) -> Group:
        return Group.objects.create(
            name=name,
            description=description,
            type=group_type,
            currency=currency,
            created_by=created_by or self.user,
            simplify_debts=simplify_debts,
        )

    def add_membership(
        self,
        group: Group,
        user: User,
        role: str = GroupRole.MEMBER,
        invited_by=None,
    ) -> GroupMember:
        return GroupMember.objects.create(
            group=group,
            user=user,
            role=role,
            invited_by=invited_by,
        )

    def authenticate(self, user=None):
        self.client.force_authenticate(user=user or self.user)

    def create_expense(
        self,
        *,
        group=None,
        paid_by=None,
        created_by=None,
        amount="60.00",
        currency="BRL",
        exchange_rate_to_group_currency="1.000000",
        amount_in_group_currency=None,
        description="Groceries",
        category="geral",
        split_method=SplitMethod.EQUAL,
    ) -> Expense:
        normalized_amount = Decimal(str(amount)).quantize(Decimal("0.01"))
        normalized_group_amount = Decimal(
            str(amount_in_group_currency if amount_in_group_currency is not None else amount)
        ).quantize(Decimal("0.01"))

        return Expense.objects.create(
            group=group,
            paid_by=paid_by or self.user,
            amount=normalized_amount,
            currency=currency,
            exchange_rate_to_group_currency=exchange_rate_to_group_currency,
            amount_in_group_currency=normalized_group_amount,
            description=description,
            category=category,
            split_method=split_method,
            created_by=created_by or self.user,
        )

    def create_split(
        self,
        expense: Expense,
        user: User,
        amount_owed,
        *,
        share_value=None,
        is_settled=False,
    ) -> Split:
        return Split.objects.create(
            expense=expense,
            user=user,
            amount_owed=Decimal(str(amount_owed)).quantize(Decimal("0.01")),
            share_value=share_value,
            is_settled=is_settled,
        )

    def create_transaction(
        self,
        *,
        group=None,
        payer=None,
        receiver=None,
        amount="10.00",
        currency="BRL",
        note="Settlement",
        is_confirmed=False,
        is_disputed=False,
    ) -> Transaction:
        return Transaction.objects.create(
            group=self.group if group is None else group,
            payer=payer or self.user,
            receiver=receiver or self.member_user,
            amount=Decimal(str(amount)).quantize(Decimal("0.01")),
            currency=currency,
            note=note,
            is_confirmed=is_confirmed,
            is_disputed=is_disputed,
        )


class TransactionServiceTests(TransactionTestMixin, TestCase):
    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    def test_create_saves_pending_transaction_and_dispatches_email_on_commit(self, mock_delay):
        payload = {
            "receiver_id": self.member_user.id,
            "amount": Decimal("15.00"),
            "currency": "BRL",
            "group_id": self.group.id,
            "note": "Partial settlement",
        }

        with self.captureOnCommitCallbacks(execute=True):
            txn = TransactionService.create(self.user, payload)

        txn.refresh_from_db()

        self.assertFalse(txn.is_confirmed)
        self.assertFalse(txn.is_disputed)
        self.assertEqual(txn.payer, self.user)
        self.assertEqual(txn.receiver, self.member_user)
        self.assertEqual(txn.amount, Decimal("15.00"))
        self.assertEqual(mock_delay.call_count, 1)
        self.assertEqual(
            mock_delay.call_args.args,
            (str(self.user.id), str(self.member_user.id), str(txn.id)),
        )

    @patch("tasks.email_tasks.send_settlement_confirmation.delay")
    @patch("tasks.ledger_tasks.recalculate_group_ledger.delay")
    def test_confirm_sets_is_confirmed_and_dispatches_recalculation_on_commit(
        self,
        mock_recalculate_delay,
        mock_email_delay,
    ):
        txn = self.create_transaction(payer=self.user, receiver=self.member_user, is_confirmed=False)

        with self.captureOnCommitCallbacks(execute=True):
            TransactionService.confirm(txn, self.member_user)

        txn.refresh_from_db()

        self.assertTrue(txn.is_confirmed)
        self.assertEqual(mock_recalculate_delay.call_count, 1)
        self.assertEqual(mock_recalculate_delay.call_args.args, (str(self.group.id),))
        self.assertEqual(mock_email_delay.call_count, 1)
        self.assertEqual(
            mock_email_delay.call_args.args,
            (str(self.user.id), str(self.member_user.id), str(txn.id)),
        )

    def test_confirm_raises_permission_denied_for_payer(self):
        txn = self.create_transaction(payer=self.user, receiver=self.member_user)

        with self.assertRaisesMessage(
            PermissionDenied,
            "Only the receiver can confirm this transaction.",
        ):
            TransactionService.confirm(txn, self.user)

    def test_confirm_raises_value_error_when_already_confirmed(self):
        txn = self.create_transaction(is_confirmed=True)

        with self.assertRaisesMessage(ValueError, "Transaction is already confirmed."):
            TransactionService.confirm(txn, self.member_user)

    def test_confirm_raises_value_error_when_disputed(self):
        txn = self.create_transaction(is_disputed=True)

        with self.assertRaisesMessage(
            ValueError,
            "Transaction is disputed. Resolve dispute first.",
        ):
            TransactionService.confirm(txn, self.member_user)

    def test_dispute_sets_is_disputed_and_creates_audit_log(self):
        txn = self.create_transaction(payer=self.user, receiver=self.member_user)

        disputed = TransactionService.dispute(txn, self.member_user)
        disputed.refresh_from_db()

        self.assertTrue(disputed.is_disputed)
        audit_log = AuditLog.objects.get(target_id=txn.id, action="TRANSACTION_DISPUTED")
        self.assertEqual(audit_log.actor, self.member_user)
        self.assertEqual(audit_log.target_type, "transaction")
        self.assertEqual(audit_log.before_state, {"is_disputed": False})
        self.assertEqual(
            audit_log.after_state,
            {"is_disputed": True, "disputed_by": str(self.member_user.id)},
        )

    def test_dispute_raises_permission_denied_for_payer(self):
        txn = self.create_transaction(payer=self.user, receiver=self.member_user)

        with self.assertRaisesMessage(
            PermissionDenied,
            "Only the receiver can dispute this transaction.",
        ):
            TransactionService.dispute(txn, self.user)

    def test_dispute_raises_value_error_when_confirmed(self):
        txn = self.create_transaction(is_confirmed=True)

        with self.assertRaisesMessage(ValueError, "Cannot dispute a confirmed transaction."):
            TransactionService.dispute(txn, self.member_user)

    def test_list_pending_returns_only_non_confirmed_non_disputed_transactions(self):
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

        result_ids = list(
            TransactionService.list(self.user, {"status": "pending"}).values_list("id", flat=True)
        )

        self.assertEqual(result_ids, [pending.id])

    def test_list_returns_only_transactions_where_user_is_payer_or_receiver(self):
        payer_side = self.create_transaction(payer=self.user, receiver=self.member_user, amount="9.00")
        receiver_side = self.create_transaction(
            payer=self.member_user,
            receiver=self.user,
            amount="8.00",
        )
        self.create_transaction(
            payer=self.member_user,
            receiver=self.third_user,
            amount="7.00",
        )

        queryset = TransactionService.list(self.user, {})
        result_ids = list(queryset.values_list("id", flat=True))

        self.assertEqual(result_ids, [receiver_side.id, payer_side.id])
