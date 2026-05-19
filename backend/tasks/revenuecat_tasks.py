import logging
from datetime import datetime, timezone as tz

from celery import shared_task

logger = logging.getLogger(__name__)

_GRANT_TYPES = frozenset({"INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE"})
_REVOKE_TYPES = frozenset({"CANCELLATION", "EXPIRATION"})


def _plan_type_from_rc_event(event: dict) -> str | None:
    pid = str(event.get("product_id") or "").lower()
    if any(
        s in pid
        for s in (
            "lifetime",
            "life_time",
            "non_renewing",
            "nonrenewing",
            "one_time",
            "onetime",
        )
    ):
        return "lifetime"
    if any(s in pid for s in ("year", "annual", "yr")):
        return "yearly"
    if any(s in pid for s in ("month", "monthly")):
        return "monthly"
    period = str(event.get("period_type") or "").upper()
    if period in ("YEARLY", "ANNUAL"):
        return "yearly"
    if period in ("MONTHLY", "NORMAL"):
        return "monthly"
    return None


def _expires_from_event(event: dict) -> datetime | None:
    raw = event.get("expiration_at_ms")
    if raw is None:
        return None
    try:
        return datetime.fromtimestamp(int(raw) / 1000.0, tz=tz.utc)
    except (TypeError, ValueError, OSError):
        return None


@shared_task(bind=True, max_retries=5, default_retry_delay=60, task_acks_late=True)
def process_rc_webhook(self, payload: dict):
    try:
        from apps.ads.services import AdsService
        from apps.users.models import User

        event = payload.get("event") or {}
        if not isinstance(event, dict):
            event = {}
        event_type = event.get("type") or ""
        app_user_id = event.get("app_user_id")
        if not app_user_id:
            logger.warning("[revenuecat_tasks] webhook missing app_user_id")
            return

        try:
            user = User.objects.get(id=app_user_id)
        except User.DoesNotExist:
            logger.warning(
                "[revenuecat_tasks] unknown app_user_id=%s",
                app_user_id,
            )
            return
        except (ValueError, TypeError):
            logger.warning(
                "[revenuecat_tasks] invalid app_user_id=%r",
                app_user_id,
            )
            return

        plan_type = _plan_type_from_rc_event(event)
        expires = _expires_from_event(event)

        if event_type in _GRANT_TYPES:
            AdsService.apply_revenuecat_entitlement(
                user,
                grant=True,
                subscription_status="active",
                plan_expires_at=expires,
                plan_type=plan_type,
            )
        elif event_type in _REVOKE_TYPES:
            sub_status = "canceled" if event_type == "CANCELLATION" else "expired"
            AdsService.apply_revenuecat_entitlement(
                user,
                grant=False,
                subscription_status=sub_status,
                plan_expires_at=None,
                plan_type=None,
            )
        else:
            logger.debug("[revenuecat_tasks] ignoring event_type=%s", event_type)
    except Exception as exc:
        logger.exception("[revenuecat_tasks] process_rc_webhook failed: %s", exc)
        raise self.retry(exc=exc) from exc
