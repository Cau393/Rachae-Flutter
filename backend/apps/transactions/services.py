from decimal import Decimal
from typing import Any, List

from django.db import transaction as db_transaction
from django.db.models import Q, QuerySet, Sum
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied

from apps.transactions.models import Transaction
from apps.users.models import User
from core.models import AuditLog


class TransactionService:
    CENT = Decimal("0.01")
    ZERO = Decimal("0.00")

    @staticmethod
    def list(user, filters: dict) -> QuerySet:
        filters = filters or {}

        queryset = Transaction.objects.filter(
            Q(payer=user) | Q(receiver=user)
        ).select_related("payer", "receiver", "group")

        if filters.get("group_id"):
            queryset = queryset.filter(group_id=filters["group_id"])
        if filters.get("with_user"):
            queryset = queryset.filter(
                Q(payer=user, receiver_id=filters["with_user"])
                | Q(payer_id=filters["with_user"], receiver=user)
            )

        status_filter = filters.get("status")
        if status_filter == "confirmed":
            queryset = queryset.filter(is_confirmed=True)
        elif status_filter == "disputed":
            queryset = queryset.filter(is_disputed=True)
        elif status_filter == "pending":
            queryset = queryset.filter(is_confirmed=False, is_disputed=False)

        pending_role = filters.get("pending_role")
        if pending_role == "receiver":
            queryset = queryset.filter(
                receiver=user,
                is_confirmed=False,
                is_disputed=False,
            )
        elif pending_role == "payer":
            queryset = queryset.filter(
                payer=user,
                is_confirmed=False,
                is_disputed=False,
            )

        return queryset.order_by("-created_at")

    @staticmethod
    def get(transaction_id, requesting_user) -> Transaction:
        txn = get_object_or_404(
            Transaction.objects.select_related("payer", "receiver", "group"),
            id=transaction_id,
        )

        if txn.payer_id != requesting_user.id and txn.receiver_id != requesting_user.id:
            raise PermissionDenied("You are not involved in this transaction.")

        return txn

    @staticmethod
    def _max_recordable_to_receiver(payer: User, receiver: User) -> Decimal:
        """How much [payer] may still record paying [receiver] (BRL, 2 dp)."""
        from apps.users.services import BalanceService

        raw = BalanceService.get_pairwise_balance(payer, receiver)["balance"]
        bal = Decimal(str(raw)).quantize(Decimal("0.01"))
        # Friend-balance convention: negative => payer owes receiver.
        return max(Decimal("0.00"), -bal).quantize(Decimal("0.01"))
    
    @staticmethod
    def _pending_outbound_total(
        payer: User, receiver: User, *, group_id=None
    ) -> Decimal:
        """Calculates how much money is currently waiting for the receiver to approve."""
        qs = Transaction.objects.filter(
            payer=payer,
            receiver=receiver,
            is_confirmed=False,
            is_disputed=False,
        )
        if group_id is not None:
            qs = qs.filter(group_id=group_id)
            
        total = qs.aggregate(s=Sum("amount"))["s"]
        if total is None:
            return TransactionService.ZERO
            
        return Decimal(str(total)).quantize(TransactionService.CENT)

    @staticmethod
    def _group_ids_equal(a, b) -> bool:
        if a is None and b is None:
            return True
        if a is None or b is None:
            return False
        return str(a) == str(b)

    @staticmethod
    def _credit_receiver_owes_payer_excluding_group(
        payer: User, receiver: User, exclude_group_id
    ) -> Decimal:
        """
        Sum of per-group debts where receiver owes payer, excluding exclude_group_id
        (report currency). Used for offset eligibility and preview.
        """
        debts = TransactionService._get_debt_breakdown(str(receiver.id), str(payer.id))
        total = TransactionService.ZERO
        for d in debts:
            if TransactionService._group_ids_equal(d["group_id"], exclude_group_id):
                continue
            total += Decimal(str(d["amount"])).quantize(TransactionService.CENT)
        return total.quantize(TransactionService.CENT)

    @staticmethod
    def offset_credit_excluding_group(payer: User, receiver: User, exclude_group_id) -> dict:
        """Read-only payload for offset preview API."""
        from apps.users.services import BalanceService

        credit = TransactionService._credit_receiver_owes_payer_excluding_group(
            payer, receiver, exclude_group_id
        )
        return {
            "credit": credit,
            "currency": BalanceService.REPORT_CURRENCY,
        }

    @staticmethod
    def _max_owed_via_splits_in_group(
        payer: User, receiver: User, group_id
    ) -> Decimal:
        """How much [payer] still owes [receiver] in a specific group."""
        for debt in TransactionService._get_debt_breakdown(payer.id, receiver.id):
            if str(debt["group_id"]) == str(group_id):
                return debt["amount"]
        return Decimal("0.00")

    @staticmethod
    def _get_debt_breakdown(payer_id, receiver_id) -> List[dict[str, Any]]:
        """
        Return debts grouped by group_id where payer owes receiver.

        Uses the same expense/split/currency rules and non-disputed settlement
        deductions as BalanceService pairwise balances (report currency).
        """
        from apps.users.queries import convert_amount, get_pairwise_expenses
        from apps.users.services import BalanceService

        expenses = get_pairwise_expenses(payer_id, receiver_id)

        net_by_group: dict[str, Decimal] = {}
        group_ids: dict[str, object] = {}

        for expense in expenses:
            gid = str(expense.group_id)
            group_ids[gid] = expense.group_id
            net_by_group.setdefault(gid, TransactionService.ZERO)

            base_currency = expense.group.currency if expense.group_id else expense.currency

            for split in expense.splits.all():
                if split.user_id == expense.paid_by_id:
                    continue

                converted_amount = convert_amount(
                    split.amount_owed, base_currency, BalanceService.REPORT_CURRENCY
                )

                if (
                    str(expense.paid_by_id) == str(receiver_id)
                    and str(split.user_id) == str(payer_id)
                ):
                    net_by_group[gid] += converted_amount
                elif (
                    str(expense.paid_by_id) == str(payer_id)
                    and str(split.user_id) == str(receiver_id)
                ):
                    net_by_group[gid] -= converted_amount

        txn_rows = Transaction.objects.filter(is_disputed=False).filter(
            Q(payer_id=payer_id, receiver_id=receiver_id)
            | Q(payer_id=receiver_id, receiver_id=payer_id)
        )

        for txn in txn_rows:
            gid = str(txn.group_id)
            group_ids[gid] = txn.group_id
            net_by_group.setdefault(gid, TransactionService.ZERO)

            converted_amount = convert_amount(
                txn.amount, txn.currency, BalanceService.REPORT_CURRENCY
            )

            if str(txn.payer_id) == str(payer_id) and str(txn.receiver_id) == str(
                receiver_id
            ):
                net_by_group[gid] -= converted_amount
            elif str(txn.payer_id) == str(receiver_id) and str(txn.receiver_id) == str(
                payer_id
            ):
                net_by_group[gid] += converted_amount

        debts = [
            {
                "group_id": group_ids[gid],
                "amount": amount.quantize(TransactionService.CENT),
            }
            for gid, amount in net_by_group.items()
            if amount > TransactionService.ZERO
        ]
        return sorted(
            debts,
            key=lambda row: (row["amount"], str(row["group_id"])),
            reverse=True,
        )

    @staticmethod
    def _calculate_debts_by_group(payer: User, receiver: User) -> List[dict[str, Any]]:
        """
        Backward-compatible alias to the canonical debt breakdown helper.
        """
        return TransactionService._get_debt_breakdown(payer.id, receiver.id)

    @staticmethod
    def _new_transaction(
        *,
        payer: User,
        receiver_id,
        amount: Decimal,
        currency: str,
        group_id,
        note,
        proof_urls: List[str],
    ) -> Transaction:
        return Transaction.objects.create(
            payer=payer,
            receiver_id=receiver_id,
            amount=amount.quantize(TransactionService.CENT),
            currency=currency,
            group_id=group_id,
            note=note,
            proof_urls=list(proof_urls),
        )

    @staticmethod
    def _queue_settlement_confirmation_emails(transactions: List[Transaction]) -> None:
        from tasks.email_tasks import send_settlement_confirmation

        for txn in transactions:
            uid = str(txn.payer_id)
            rid = str(txn.receiver_id)
            tid = str(txn.id)
            db_transaction.on_commit(
                lambda u=uid, r=rid, t=tid: send_settlement_confirmation.delay(
                    u, r, t
                )
            )

    @staticmethod
    def _create_waterfall_transactions(
        *,
        payer: User,
        receiver_id,
        amount: Decimal,
        currency: str,
        note,
        proof_urls: List[str],
        debts_by_group: List[dict[str, Any]],
        allow_personal_residual: bool = True,
    ) -> List[Transaction]:
        created_transactions: List[Transaction] = []
        remaining = amount

        for debt in debts_by_group:
            if remaining <= TransactionService.ZERO:
                break
            debt_amount = Decimal(str(debt["amount"])).quantize(TransactionService.CENT)
            if debt_amount <= TransactionService.ZERO:
                continue
            amount_to_pay = min(remaining, debt_amount).quantize(TransactionService.CENT)
            created_transactions.append(
                TransactionService._new_transaction(
                    payer=payer,
                    receiver_id=receiver_id,
                    amount=amount_to_pay,
                    currency=currency,
                    group_id=debt["group_id"],
                    note=note,
                    proof_urls=proof_urls,
                )
            )
            remaining = (remaining - amount_to_pay).quantize(TransactionService.CENT)

        if remaining > TransactionService.ZERO:
            if not allow_personal_residual:
                raise ValueError(
                    "Offset reverse waterfall could not allocate the full amount "
                    "across non-offset groups."
                )
            created_transactions.append(
                TransactionService._new_transaction(
                    payer=payer,
                    receiver_id=receiver_id,
                    amount=remaining,
                    currency=currency,
                    group_id=None,
                    note=note,
                    proof_urls=proof_urls,
                )
            )

        return created_transactions

    @staticmethod
    def create(payer, validated_data) -> List[Transaction]:
        receiver = get_object_or_404(User, id=validated_data["receiver_id"])
        amount = validated_data["amount"]
        amt = (
            amount.quantize(TransactionService.CENT)
            if isinstance(amount, Decimal)
            else Decimal(str(amount)).quantize(TransactionService.CENT)
        )
        proof_urls = list(validated_data.get("proof_urls") or [])
        currency = validated_data.get("currency", "BRL")
        note = validated_data.get("note")

        max_pay = TransactionService._max_recordable_to_receiver(payer, receiver)
        gid = validated_data.get("group_id")
        if gid is not None:
            # Group Settlement: Cap only at what is owed in this specific group
            group_max = TransactionService._max_owed_via_splits_in_group(
                payer, receiver, gid
            )
            effective_max = group_max.quantize(TransactionService.CENT)
            pending = TransactionService._pending_outbound_total(
                payer, receiver, group_id=gid
            )
            if effective_max <= TransactionService.ZERO:
                raise ValueError("You do not owe this user any money in this group.")
        else:
            # Global Settlement (Waterfall): Cap at the global net debt
            effective_max = max_pay.quantize(TransactionService.CENT)
            pending = TransactionService._pending_outbound_total(
                payer, receiver, group_id=None
            )
            if effective_max <= TransactionService.ZERO:
                raise ValueError("You do not owe this user any money globally.")

        if amt + pending > effective_max:
            raise ValueError(
                "Amount exceeds what you owe this person (including pending payments)."
            )

        with db_transaction.atomic():
            created_transactions: List[Transaction] = []

            if gid is not None:
                created_transactions.append(
                    TransactionService._new_transaction(
                        payer=payer,
                        receiver_id=validated_data["receiver_id"],
                        amount=amt,
                        currency=currency,
                        group_id=gid,
                        note=note,
                        proof_urls=proof_urls,
                    )
                )
            else:
                created_transactions = TransactionService._create_waterfall_transactions(
                    payer=payer,
                    receiver_id=validated_data["receiver_id"],
                    amount=amt,
                    currency=currency,
                    note=note,
                    proof_urls=proof_urls,
                    debts_by_group=TransactionService._get_debt_breakdown(
                        payer.id,
                        receiver.id,
                    ),
                )

            TransactionService._queue_settlement_confirmation_emails(created_transactions)

        return created_transactions

    @staticmethod
    def create_offset(payer, validated_data) -> List[Transaction]:
        """
        Double-entry offset: payer pays receiver in group_id, then receiver pays payer
        across other groups/personal (reverse waterfall) for the same amount.
        """
        receiver = get_object_or_404(User, id=validated_data["receiver_id"])
        amount = validated_data["amount"]
        amt = (
            amount.quantize(TransactionService.CENT)
            if isinstance(amount, Decimal)
            else Decimal(str(amount)).quantize(TransactionService.CENT)
        )
        proof_urls = list(validated_data.get("proof_urls") or [])
        currency = validated_data.get("currency", "BRL")
        note = validated_data.get("note")

        gid = validated_data.get("group_id")
        if gid is None:
            raise ValueError("Offset settlements require a group.")

        group_max = TransactionService._max_owed_via_splits_in_group(
            payer, receiver, gid
        )
        effective_max = group_max.quantize(TransactionService.CENT)
        pending = TransactionService._pending_outbound_total(
            payer, receiver, group_id=gid
        )
        if effective_max <= TransactionService.ZERO:
            raise ValueError("You do not owe this user any money in this group.")
        if amt + pending > effective_max:
            raise ValueError(
                "Amount exceeds what you owe this person (including pending payments)."
            )

        credit = TransactionService._credit_receiver_owes_payer_excluding_group(
            payer, receiver, gid
        )
        if credit < amt:
            raise ValueError(
                "You do not have enough credit with this user to offset this amount"
            )

        reverse_debts = [
            d
            for d in TransactionService._get_debt_breakdown(
                str(receiver.id), str(payer.id)
            )
            if not TransactionService._group_ids_equal(d["group_id"], gid)
        ]
        allocatable = sum(
            Decimal(str(d["amount"])).quantize(TransactionService.CENT)
            for d in reverse_debts
        ).quantize(TransactionService.CENT)
        if allocatable < amt:
            raise ValueError(
                "You do not have enough credit with this user to offset this amount"
            )

        with db_transaction.atomic():
            created_transactions: List[Transaction] = [
                TransactionService._new_transaction(
                    payer=payer,
                    receiver_id=validated_data["receiver_id"],
                    amount=amt,
                    currency=currency,
                    group_id=gid,
                    note=note,
                    proof_urls=proof_urls,
                )
            ]
            created_transactions.extend(
                TransactionService._create_waterfall_transactions(
                    payer=receiver,
                    receiver_id=payer.id,
                    amount=amt,
                    currency=currency,
                    note=note,
                    proof_urls=proof_urls,
                    debts_by_group=reverse_debts,
                    allow_personal_residual=False,
                )
            )
            TransactionService._queue_settlement_confirmation_emails(
                created_transactions
            )

        return created_transactions

    @staticmethod
    def confirm(txn, actor) -> Transaction:
        from tasks.email_tasks import send_settlement_confirmation
        from tasks.ledger_tasks import recalculate_group_ledger

        if txn.receiver_id != actor.id:
            raise PermissionDenied("Only the receiver can confirm this transaction.")
        if txn.is_confirmed:
            raise ValueError("Transaction is already confirmed.")
        if txn.is_disputed:
            raise ValueError("Transaction is disputed. Resolve dispute first.")

        with db_transaction.atomic():
            txn.is_confirmed = True
            txn.save(update_fields=["is_confirmed"])

            if txn.group_id is not None:
                gid = str(txn.group_id)
                db_transaction.on_commit(
                    lambda group_id=gid: recalculate_group_ledger.delay(group_id)
                )

            uid = str(txn.payer_id)
            rid = str(txn.receiver_id)
            tid = str(txn.id)
            db_transaction.on_commit(
                lambda u=uid, r=rid, t=tid: send_settlement_confirmation.delay(
                    u, r, t
                )
            )

        return txn

    @staticmethod
    def dispute(txn, actor) -> Transaction:
        if txn.receiver_id != actor.id:
            raise PermissionDenied("Only the receiver can dispute this transaction.")
        if txn.is_confirmed:
            raise ValueError("Cannot dispute a confirmed transaction.")
        if txn.is_disputed:
            raise ValueError("Transaction is already disputed.")

        with db_transaction.atomic():
            txn.is_disputed = True
            txn.save(update_fields=["is_disputed"])

            AuditLog.objects.create(
                actor=actor,
                action="TRANSACTION_DISPUTED",
                target_type="transaction",
                target_id=txn.id,
                before_state={"is_disputed": False},
                after_state={"is_disputed": True, "disputed_by": str(actor.id)},
            )

        return txn
