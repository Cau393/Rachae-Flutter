import heapq
from decimal import Decimal
from typing import Any

from django.db.models import Sum

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
    """
    from apps.expenses.models import Expense
    from apps.groups.models import GroupMember
    from apps.splits.models import Split
    Transaction = None
    try:
        from apps.transactions.models import Transaction
    except ImportError:
        pass

    result: dict[str, Decimal] = {}

    members = GroupMember.objects.filter(
        group_id=group_id,
        is_deleted=False,
    ).select_related("user")

    for member in members:
        user = member.user

        paid = (
            Expense.objects.filter(
                group_id=group_id,
                paid_by=user,
                is_deleted=False,
            ).aggregate(total=Sum("amount_in_group_currency"))["total"]
        ) or Decimal("0")

        owed = (
            Split.objects.filter(
                expense__group_id=group_id,
                expense__is_deleted=False,
                user=user,
                is_settled=False,
            ).aggregate(total=Sum("amount_owed"))["total"]
        ) or Decimal("0")

        received_confirmed = Decimal("0")
        paid_confirmed = Decimal("0")
        if Transaction is not None:
            received_confirmed = (
                Transaction.objects.filter(
                    group_id=group_id,
                    receiver=user,
                    is_confirmed=True,
                ).aggregate(total=Sum("amount"))["total"]
            ) or Decimal("0")
            paid_confirmed = (
                Transaction.objects.filter(
                    group_id=group_id,
                    payer=user,
                    is_confirmed=True,
                ).aggregate(total=Sum("amount"))["total"]
            ) or Decimal("0")

        result[str(user.id)] = paid - owed + received_confirmed - paid_confirmed

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
