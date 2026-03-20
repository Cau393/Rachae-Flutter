from django.apps import apps
from celery import shared_task
from django.utils import timezone

from apps.users.models import FriendInvite


@shared_task
def delete_user_data(user_id: str):
    GroupMember = apps.get_model("groups", "GroupMember")
    Expense = apps.get_model("expenses", "Expense")
    Transaction = apps.get_model("transactions", "Transaction")

    now = timezone.now()
    GroupMember.all_objects.filter(user_id=user_id).update(is_deleted=True)
    Expense.all_objects.filter(created_by_id=user_id).update(is_deleted=True, deleted_at=now)
    Transaction.all_objects.filter(payer_id=user_id).update(is_deleted=True)
    Transaction.all_objects.filter(receiver_id=user_id).update(is_deleted=True)
    FriendInvite.all_objects.filter(inviter_id=user_id).update(is_deleted=True)
    FriendInvite.all_objects.filter(accepted_by_id=user_id).update(is_deleted=True)
