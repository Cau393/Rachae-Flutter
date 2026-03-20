import heapq
from decimal import Decimal
from typing import Any

ZERO = Decimal("0")
MIN_REMAINDER = Decimal("0.01")


def _run_min_cash_flow(net_balances: dict[str, Decimal]) -> list[dict[str, Any]]:
    """
    Generate settlement suggestions using the Min Cash Flow greedy heuristic.

    Positive balances are creditors and negative balances are debtors.
    """
    creditors: list[tuple[Decimal, str]] = []
    debtors: list[tuple[Decimal, str]] = []

    for user_id, balance in net_balances.items():
        if balance > ZERO:
            heapq.heappush(creditors, (-balance, str(user_id)))
        elif balance < ZERO:
            heapq.heappush(debtors, (balance, str(user_id)))

    suggestions: list[dict[str, Any]] = []

    while creditors and debtors:
        neg_credit, receiver_id = heapq.heappop(creditors)
        debt, payer_id = heapq.heappop(debtors)

        credit = -neg_credit
        debt_amount = -debt
        transfer_amount = min(credit, debt_amount)

        suggestions.append(
            {
                "payer_id": payer_id,
                "receiver_id": receiver_id,
                "amount": transfer_amount,
            }
        )

        remaining_credit = credit - transfer_amount
        remaining_debt = debt_amount - transfer_amount

        if remaining_credit > MIN_REMAINDER:
            heapq.heappush(creditors, (-remaining_credit, receiver_id))
        if remaining_debt > MIN_REMAINDER:
            heapq.heappush(debtors, (-remaining_debt, payer_id))

    return suggestions


def run_min_cash_flow(net_balances: dict[str, Decimal]) -> list[dict[str, Any]]:
    """Public wrapper kept stable for future ledger-app reuse."""
    return _run_min_cash_flow(net_balances)
