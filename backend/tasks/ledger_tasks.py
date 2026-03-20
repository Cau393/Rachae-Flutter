import logging
from decimal import Decimal

from celery import shared_task
from django.core.cache import cache

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=30, task_acks_late=True)
def recalculate_group_ledger(self, group_id: str):
    try:
        from apps.groups.models import GroupMember
        from apps.ledger.algorithms import compute_group_net_balances as imported_compute_group_net_balances

        # Keep this indirection so test patching on tasks.ledger_tasks works.
        compute_fn = globals().get("compute_group_net_balances", imported_compute_group_net_balances)
        net_map = compute_fn(group_id)

        cache_key = f"rachae:ledger:group:{group_id}:balances"
        cache.set(
            cache_key,
            {uid: str(Decimal(str(balance))) for uid, balance in net_map.items()},
            timeout=3600,
        )

        member_user_ids = list(
            GroupMember.objects.filter(group_id=group_id).values_list("user_id", flat=True)
        )
        for uid in member_user_ids:
            cache.delete(f"rachae:ledger:user:{uid}:net_balances")

        logger.info(
            "[ledger_tasks] recalculate_group_ledger: group=%s members=%d",
            group_id,
            len(member_user_ids),
        )
    except Exception as exc:
        logger.error(
            "[ledger_tasks] recalculate_group_ledger failed: group=%s error=%s",
            group_id,
            exc,
        )
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=30, task_acks_late=True)
def run_debt_simplification(self, group_id: str):
    try:
        from apps.groups.models import Group
        from apps.ledger.algorithms import simplify_group_debts

        group = Group.objects.filter(id=group_id, is_deleted=False).first()
        if not group:
            logger.warning(
                "[ledger_tasks] run_debt_simplification: group=%s not found — skipping",
                group_id,
            )
            return

        suggestions = []
        if group.simplify_debts:
            suggestions = simplify_group_debts(str(group.id), group.currency)

        serializable = [{**s, "amount": str(s["amount"])} for s in suggestions]

        cache_key = f"rachae:ledger:group:{group_id}:simplified"
        cache.set(cache_key, serializable, timeout=3600)

        logger.info(
            "[ledger_tasks] run_debt_simplification: group=%s suggestions=%d",
            group_id,
            len(suggestions),
        )
    except Exception as exc:
        logger.error(
            "[ledger_tasks] run_debt_simplification failed: group=%s error=%s",
            group_id,
            exc,
        )
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=2, default_retry_delay=60, task_acks_late=True)
def run_debt_simplification_all_groups(self):
    try:
        from apps.groups.models import Group

        group_ids = Group.objects.filter(is_deleted=False, simplify_debts=True).values_list(
            "id", flat=True
        )
        count = 0
        for gid in group_ids:
            run_debt_simplification.delay(str(gid))
            count += 1

        logger.info("[ledger_tasks] run_debt_simplification_all_groups: dispatched=%d", count)
    except Exception as exc:
        logger.error("[ledger_tasks] run_debt_simplification_all_groups failed: %s", exc)
        raise self.retry(exc=exc)
