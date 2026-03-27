"""FIFO replay of confirmed settlements on nominal split amounts (owed_to_me list).

There is no Expense↔Transaction FK; settlement applies to Split rows in transaction
order. Listing \"others owe me\" from raw DB splits can show stale rows after payments.
We recompute remaining owed per split by replaying all confirmed transactions on
nominal shares (SplitService), then align with dashboard net (BalanceService).
"""

from __future__ import annotations

from decimal import Decimal

from django.db.models import F, Q

from apps.expenses.models import Expense, SplitMethod
from apps.expenses.services import SplitService
from apps.splits.models import Split
from apps.transactions.models import Transaction
from apps.transactions.settlement_splits import settlement_eligible_splits_list_for_pair
from apps.users.queries import get_balance_expenses_for_user
from apps.users.services import BalanceService

ZERO = Decimal("0.00")
CENT = Decimal("0.01")


def _nominal_amount_by_user_id_from_db(expense: Expense) -> dict[str, Decimal]:
    return {
        str(s.user_id): Decimal(str(s.amount_owed)).quantize(CENT)
        for s in expense.splits.filter(is_deleted=False).order_by("created_at")
    }


def _nominal_amount_by_user_id(expense: Expense) -> dict[str, Decimal]:
    """Recompute nominal shares; fall back to current DB amounts if data is incomplete."""
    splits_data: list[dict] = []
    for s in expense.splits.filter(is_deleted=False).order_by("created_at"):
        row: dict = {"user_id": str(s.user_id)}
        if expense.split_method == SplitMethod.EXACT:
            row["amount_owed"] = str(s.amount_owed)
        elif expense.split_method in (SplitMethod.PERCENTAGE, SplitMethod.SHARES):
            if s.share_value is not None:
                row["share_value"] = str(s.share_value)
        splits_data.append(row)
    if not splits_data:
        return {}
    try:
        nominal = SplitService.compute_splits(
            expense.split_method,
            splits_data,
            expense.amount_in_group_currency,
        )
        return {
            str(r["user_id"]): Decimal(str(r["amount_owed"])).quantize(CENT) for r in nominal
        }
    except (ArithmeticError, KeyError, TypeError, ValueError, ZeroDivisionError):
        return _nominal_amount_by_user_id_from_db(expense)


def _ensure_split_balance(
    split: Split,
    rem: dict[str, Decimal],
    nominal_cache: dict,
) -> str:
    sid = str(split.id)
    if sid in rem:
        return sid
    eid = split.expense_id
    if eid not in nominal_cache:
        nominal_cache[eid] = _nominal_amount_by_user_id(split.expense)
    rem[sid] = nominal_cache[eid].get(str(split.user_id), ZERO)
    return sid


def _payer_splits_for_expenses(expense_ids: set) -> dict[str, Split]:
    """One query: payer split row per expense (avoids N+1 in replay loop)."""
    if not expense_ids:
        return {}
    rows = (
        Split.objects.filter(expense_id__in=expense_ids, is_deleted=False)
        .filter(user_id=F("expense__paid_by_id"))
        .select_related("expense")
    )
    return {str(s.expense_id): s for s in rows}


def _replay_confirmed_transactions(rem: dict[str, Decimal], requesting_user_id) -> None:
    nominal_cache: dict = {}
    split_ids = list(rem.keys())
    expense_ids = set(
        Split.objects.filter(pk__in=split_ids).values_list("expense_id", flat=True)
    )
    payer_by_expense = _payer_splits_for_expenses(expense_ids)

    txns = list(
        Transaction.objects.filter(is_confirmed=True, is_disputed=False)
        .filter(Q(payer_id=requesting_user_id) | Q(receiver_id=requesting_user_id))
        .order_by("created_at")
    )
    pair_lists: dict[tuple, list] = {}
    for txn in txns:
        remaining = Decimal(str(txn.amount)).quantize(CENT)
        if remaining <= ZERO:
            continue
        pair_key = (txn.group_id, frozenset({txn.payer_id, txn.receiver_id}))
        if pair_key not in pair_lists:
            pair_lists[pair_key] = settlement_eligible_splits_list_for_pair(
                txn.group_id, txn.payer_id, txn.receiver_id
            )
        for split in pair_lists[pair_key]:
            sid = _ensure_split_balance(split, rem, nominal_cache)
            owe = rem[sid].quantize(CENT)
            if remaining <= ZERO:
                break
            if owe <= ZERO:
                continue
            take = min(owe, remaining).quantize(CENT)
            rem[sid] = (owe - take).quantize(CENT)
            payer_split = payer_by_expense.get(str(split.expense_id))
            if payer_split is None and split.expense.paid_by_id:
                # Lazy fill for expenses first seen via settlement_eligible (not in initial rem)
                payer_split = (
                    Split.objects.filter(
                        expense_id=split.expense_id,
                        user_id=split.expense.paid_by_id,
                        is_deleted=False,
                    )
                    .select_related("expense")
                    .first()
                )
                if payer_split is not None:
                    payer_by_expense[str(split.expense_id)] = payer_split
            if payer_split is not None and str(payer_split.id) != sid:
                psid = _ensure_split_balance(payer_split, rem, nominal_cache)
                ps_owe = rem[psid].quantize(CENT)
                rem[psid] = (ps_owe + take).quantize(CENT)
            remaining = (remaining - take).quantize(CENT)


def _rem_from_balance_expenses(expenses: list) -> dict[str, Decimal]:
    rem: dict[str, Decimal] = {}
    for exp in expenses:
        nom = _nominal_amount_by_user_id(exp)
        for s in exp.splits.all():
            if s.is_deleted:
                continue
            rem[str(s.id)] = nom.get(str(s.user_id), ZERO)
    return rem


def _inbound_settlement_keys_for_user(requesting_user_id) -> set[tuple]:
    """(payer_id, group_id) pairs with group_id None for personal."""
    rows = Transaction.objects.filter(
        receiver_id=requesting_user_id,
        is_confirmed=True,
        is_disputed=False,
    ).values_list("payer_id", "group_id")
    return {(pid, gid) for pid, gid in rows}


def compute_owed_to_me_expense_ids(requesting_user_id) -> list:
    """
    Expenses paid by the user where some counterparty still owes after FIFO replay
    on nominal splits. When net balance with that person is zero but they have an
    inbound confirmed settlement (FIFO cleared an older line item), still list
    remaining open split lines so the screen matches \"not yet settled on this expense\".
    """
    expenses_list = list(get_balance_expenses_for_user(requesting_user_id))
    rem = _rem_from_balance_expenses(expenses_list)
    _replay_confirmed_transactions(rem, requesting_user_id)

    net_by_peer = BalanceService.pairwise_net_balances_for_user(
        requesting_user_id,
        preloaded_expenses=expenses_list,
    )
    inbound_keys = _inbound_settlement_keys_for_user(requesting_user_id)
    out: list = []

    for exp in expenses_list:
        if exp.paid_by_id != requesting_user_id:
            continue
        for s in exp.splits.all():
            if s.is_deleted:
                continue
            if s.user_id == exp.paid_by_id:
                continue
            sid = str(s.id)
            owed_after = rem.get(sid, ZERO).quantize(CENT)
            if owed_after <= ZERO:
                continue

            net = net_by_peer.get(s.user_id, ZERO).quantize(CENT)
            gid = exp.group_id
            has_inbound = (s.user_id, gid) in inbound_keys
            if net <= ZERO and not has_inbound:
                continue

            out.append(exp.id)
            break

    return out
