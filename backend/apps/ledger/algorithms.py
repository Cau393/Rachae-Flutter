import heapq
from decimal import Decimal
from typing import Any

from django.db.models import DecimalField, Sum
from django.db.models.functions import Coalesce

THRESHOLD = Decimal("0.005")
ZERO = Decimal("0")
CENT = Decimal("0.01")


def run_min_cash_flow(net_balances: dict[str, Decimal]) -> list[dict[str, Any]]:
    """
    Simplify group debts using a greedy Min Cash Flow approach.

    Positive balances are creditors, negative balances are debtors.
    """
    creditors: list[tuple[Decimal, str]] = []
    debtors: list[tuple[Decimal, str]] = []

    for user_id, balance in net_balances.items():
        normalized_user_id = str(user_id)
        if balance > THRESHOLD:
            heapq.heappush(creditors, (-balance, normalized_user_id))
        elif balance < -THRESHOLD:
            heapq.heappush(debtors, (balance, normalized_user_id))

    suggestions: list[dict[str, Any]] = []

    while creditors and debtors:
        neg_credit, receiver_id = heapq.heappop(creditors)
        debt_signed, payer_id = heapq.heappop(debtors)

        credit = -neg_credit
        debt = -debt_signed
        amount = min(credit, debt).quantize(CENT)

        if amount > ZERO:
            suggestions.append(
                {
                    "payer_id": payer_id,
                    "receiver_id": receiver_id,
                    "amount": amount,
                }
            )

        remaining_credit = credit - amount
        remaining_debt = debt - amount

        if remaining_credit > THRESHOLD:
            heapq.heappush(creditors, (-remaining_credit, receiver_id))
        if remaining_debt > THRESHOLD:
            heapq.heappush(debtors, (-remaining_debt, payer_id))

    return suggestions


def compute_group_net_balances(group_id: str) -> dict[str, Decimal]:
    """
    Compute paid minus owed for each active member in a group.

    Runs 4 bulk aggregate (GROUP BY) queries total instead of 4 queries per member.
    """
    from apps.expenses.models import Expense
    from apps.groups.models import GroupMember
    from apps.splits.models import Split
    from apps.transactions.models import Transaction

    decimal_zero = Decimal("0")
    money_field = DecimalField(max_digits=12, decimal_places=2)

    member_ids = list(
        GroupMember.objects.filter(
            group_id=group_id,
            is_deleted=False,
        ).values_list("user_id", flat=True)
    )

    result: dict[str, Decimal] = {str(user_id): decimal_zero for user_id in member_ids}

    paid_expenses_by_user = {
        row["paid_by_id"]: row["total"]
        for row in Expense.objects.filter(
            group_id=group_id,
            is_deleted=False,
        )
        .values("paid_by_id")
        .annotate(total=Coalesce(Sum("amount_in_group_currency"), decimal_zero, output_field=money_field))
    }

    owed_splits_by_user = {
        row["user_id"]: row["total"]
        for row in Split.objects.filter(
            expense__group_id=group_id,
            expense__is_deleted=False,
        )
        .values("user_id")
        .annotate(total=Coalesce(Sum("amount_owed"), decimal_zero, output_field=money_field))
    }

    paid_txns_by_user = {
        row["payer_id"]: row["total"]
        for row in Transaction.objects.filter(
            group_id=group_id,
            is_disputed=False,
        )
        .values("payer_id")
        .annotate(total=Coalesce(Sum("amount"), decimal_zero, output_field=money_field))
    }

    received_txns_by_user = {
        row["receiver_id"]: row["total"]
        for row in Transaction.objects.filter(
            group_id=group_id,
            is_disputed=False,
        )
        .values("receiver_id")
        .annotate(total=Coalesce(Sum("amount"), decimal_zero, output_field=money_field))
    }

    for user_id in member_ids:
        paid_expenses = paid_expenses_by_user.get(user_id, decimal_zero)
        owed_splits = owed_splits_by_user.get(user_id, decimal_zero)
        paid_txns = paid_txns_by_user.get(user_id, decimal_zero)
        received_txns = received_txns_by_user.get(user_id, decimal_zero)

        result[str(user_id)] = (paid_expenses + paid_txns) - (owed_splits + received_txns)

    return result


def simplify_group_debts(group_id: str, currency: str) -> list[dict[str, Any]]:
    """
    Compute and enrich simplified settlement suggestions for a group.
    """
    from apps.users.models import User

    raw_suggestions = run_min_cash_flow(compute_group_net_balances(group_id))
    user_ids = {
        suggestion["payer_id"]
        for suggestion in raw_suggestions
    } | {
        suggestion["receiver_id"]
        for suggestion in raw_suggestions
    }
    user_names = {
        str(user.id): user.display_name
        for user in User.objects.filter(id__in=user_ids).only("id", "display_name")
    }

    return [
        {
            "payer_id": suggestion["payer_id"],
            "payer_name": user_names.get(suggestion["payer_id"], ""),
            "receiver_id": suggestion["receiver_id"],
            "receiver_name": user_names.get(suggestion["receiver_id"], ""),
            "amount": suggestion["amount"],
            "currency": currency,
        }
        for suggestion in raw_suggestions
    ]
