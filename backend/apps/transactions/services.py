from django.db import transaction as db_transaction
from django.db.models import Q, QuerySet
from django.shortcuts import get_object_or_404
from rest_framework.exceptions import PermissionDenied

from apps.transactions.models import Transaction
from core.models import AuditLog


class TransactionService:
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
    def create(payer, validated_data) -> Transaction:
        from tasks.email_tasks import send_settlement_confirmation

        with db_transaction.atomic():
            txn = Transaction.objects.create(
                payer=payer,
                receiver_id=validated_data["receiver_id"],
                amount=validated_data["amount"],
                currency=validated_data.get("currency", "BRL"),
                group_id=validated_data.get("group_id"),
                note=validated_data.get("note"),
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
