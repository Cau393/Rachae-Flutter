import logging

from celery import shared_task

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=5, default_retry_delay=60, task_acks_late=True)
def process_rc_webhook(self, payload: dict):
    """Thin Celery wrapper around AdsService.process_rc_event, kept for
    queued retries. The webhook view itself now calls the service function
    synchronously in-request so is_ad_free updates land before the 200
    response.
    """
    try:
        from apps.ads.services import AdsService

        AdsService.process_rc_event(payload)
    except Exception as exc:
        logger.exception("[revenuecat_tasks] process_rc_webhook failed: %s", exc)
        raise self.retry(exc=exc) from exc
