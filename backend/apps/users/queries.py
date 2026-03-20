from decimal import Decimal

from django.apps import apps
from django.db.models import Prefetch, Q, Subquery

from apps.users.models import FriendInvite, FriendInviteStatus, User


def search_users(query: str, current_user_id, limit: int = 20):
    return (
        User.objects.filter(Q(email__icontains=query) | Q(phone__icontains=query))
        .exclude(id=current_user_id)
        .order_by("display_name", "email")[:limit]
    )


def list_friends(user_id):
    group_member_model = apps.get_model("groups", "GroupMember")
    transaction_model = apps.get_model("transactions", "Transaction")

    shared_group_ids = group_member_model.objects.filter(user_id=user_id).values("group_id")
    group_friend_ids = group_member_model.objects.filter(group_id__in=Subquery(shared_group_ids)).exclude(
        user_id=user_id
    )
    transaction_friend_ids = transaction_model.objects.filter(payer_id=user_id).values_list("receiver_id", flat=True)
    transaction_counterparty_ids = transaction_model.objects.filter(receiver_id=user_id).values_list(
        "payer_id", flat=True
    )

    invite_friend_ids = set()
    accepted_invites = FriendInvite.objects.filter(status=FriendInviteStatus.ACCEPTED).filter(
        Q(inviter_id=user_id) | Q(accepted_by_id=user_id)
    )
    for invite in accepted_invites.only("inviter_id", "accepted_by_id"):
        counterpart_id = invite.accepted_by_id if invite.inviter_id == user_id else invite.inviter_id
        if counterpart_id:
            invite_friend_ids.add(counterpart_id)

    friend_ids = set(group_friend_ids.values_list("user_id", flat=True))
    friend_ids.update(transaction_friend_ids)
    friend_ids.update(transaction_counterparty_ids)
    friend_ids.update(invite_friend_ids)

    return User.objects.filter(id__in=friend_ids).order_by("display_name", "email")


def get_pending_invite_by_token(token: str):
    return (
        FriendInvite.objects.select_related("inviter", "accepted_by")
        .filter(token=token, status=FriendInviteStatus.PENDING)
        .first()
    )


def get_latest_exchange_rate(base_currency: str, quote_currency: str):
    exchange_rate_model = apps.get_model("currencies", "ExchangeRate")
    return (
        exchange_rate_model.objects.filter(base_currency=base_currency, quote_currency=quote_currency)
        .order_by("-fetched_at")
        .first()
    )


def get_balance_expenses_for_user(user_id):
    expense_model = apps.get_model("expenses", "Expense")
    split_model = apps.get_model("splits", "Split")

    split_queryset = split_model.objects.select_related("user").order_by("created_at")
    return (
        expense_model.objects.filter(Q(paid_by_id=user_id) | Q(splits__user_id=user_id))
        .select_related("group", "paid_by")
        .prefetch_related(Prefetch("splits", queryset=split_queryset))
        .distinct()
    )


def get_pairwise_expenses(current_user_id, other_user_id):
    expense_model = apps.get_model("expenses", "Expense")
    split_model = apps.get_model("splits", "Split")

    split_queryset = split_model.objects.select_related("user").order_by("created_at")
    return (
        expense_model.objects.filter(
            Q(paid_by_id=current_user_id, splits__user_id=other_user_id)
            | Q(paid_by_id=other_user_id, splits__user_id=current_user_id)
        )
        .select_related("group", "paid_by")
        .prefetch_related(Prefetch("splits", queryset=split_queryset))
        .distinct()
    )


def get_transactions_for_user(user_id):
    transaction_model = apps.get_model("transactions", "Transaction")
    return transaction_model.objects.filter(Q(payer_id=user_id) | Q(receiver_id=user_id)).select_related(
        "payer", "receiver"
    )


def get_pairwise_transactions(current_user_id, other_user_id):
    transaction_model = apps.get_model("transactions", "Transaction")
    return transaction_model.objects.filter(
        Q(payer_id=current_user_id, receiver_id=other_user_id)
        | Q(payer_id=other_user_id, receiver_id=current_user_id)
    ).select_related("payer", "receiver")


def convert_amount(amount: Decimal, source_currency: str, target_currency: str) -> Decimal:
    if source_currency == target_currency:
        return amount

    direct_rate = get_latest_exchange_rate(source_currency, target_currency)
    if direct_rate:
        return amount * direct_rate.rate

    inverse_rate = get_latest_exchange_rate(target_currency, source_currency)
    if inverse_rate and inverse_rate.rate:
        return amount / inverse_rate.rate

    # Phase 3 uses BRL as the conservative reporting currency; if no rate is
    # available yet, preserve the amount to avoid breaking the endpoint.
    return amount
