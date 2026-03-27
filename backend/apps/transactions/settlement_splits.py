"""Apply confirmed group settlements to Split rows (FIFO).

Each payment reduces the counterparty's amount_owed and increases the expense
payer's amount_owed by the same amount so split totals still match the expense
and group net balances stay conserved without double-counting Transaction rows
in the ledger.
"""

from decimal import Decimal

from django.db.models import Prefetch, Q

from apps.splits.models import Split
from apps.transactions.models import Transaction

ZERO = Decimal("0.00")
CENT = Decimal("0.01")


def _settlement_pair_q(transaction: Transaction) -> Q:
    return Q(
        expense__paid_by_id=transaction.payer_id,
        user_id=transaction.receiver_id,
    ) | Q(
        expense__paid_by_id=transaction.receiver_id,
        user_id=transaction.payer_id,
    )


def settlement_splits_queryset(transaction: Transaction):
    """Splits this payment can apply to: same group as txn, or personal (no group) if txn has no group."""
    qs = Split.objects.filter(
        expense__is_deleted=False,
        is_deleted=False,
        is_settled=False,
    ).filter(_settlement_pair_q(transaction))
    if transaction.group_id is not None:
        qs = qs.filter(expense__group_id=transaction.group_id)
    else:
        qs = qs.filter(expense__group__isnull=True)
    return qs.select_related("expense").order_by("expense__created_at", "created_at")


def settlement_eligible_splits_queryset(transaction: Transaction):
    """Same ordering/filters as settlement_splits_queryset but includes settled rows (FIFO replay from nominal)."""
    qs = Split.objects.filter(
        expense__is_deleted=False,
        is_deleted=False,
    ).filter(_settlement_pair_q(transaction))
    if transaction.group_id is not None:
        qs = qs.filter(expense__group_id=transaction.group_id)
    else:
        qs = qs.filter(expense__group__isnull=True)
    return qs.select_related("expense").order_by("expense__created_at", "created_at")


def settlement_eligible_splits_list_for_pair(group_id, payer_id, receiver_id) -> list:
    """Evaluated splits for FIFO replay; same filters/order as settlement_eligible_splits_queryset.

    Call once per (group_id, unordered user pair) and reuse across all transactions for that pair
    to avoid one heavy query per transaction (can exceed client timeouts).
    """
    qs = Split.objects.filter(
        expense__is_deleted=False,
        is_deleted=False,
    ).filter(
        Q(expense__paid_by_id=payer_id, user_id=receiver_id)
        | Q(expense__paid_by_id=receiver_id, user_id=payer_id)
    )
    if group_id is not None:
        qs = qs.filter(expense__group_id=group_id)
    else:
        qs = qs.filter(expense__group__isnull=True)
    qs = qs.select_related("expense").prefetch_related(
        Prefetch(
            "expense__splits",
            queryset=Split.objects.filter(is_deleted=False).order_by("created_at"),
        )
    ).order_by("expense__created_at", "created_at")
    return list(qs)


def _payer_split_for_expense(expense) -> Split | None:
    return (
        Split.objects.filter(
            expense=expense,
            user_id=expense.paid_by_id,
            is_deleted=False,
        )
        .first()
    )


def apply_confirmed_group_settlement_to_splits(transaction: Transaction) -> None:
    # Deprecated intentionally: unified-ledger keeps Split rows immutable.
    pass
