import logging

from celery import shared_task

logger = logging.getLogger(__name__)

try:
    from firebase_admin import messaging
except ImportError:
    messaging = None  # Firebase not installed — push silently skipped


@shared_task(bind=True, max_retries=3, default_retry_delay=30, task_acks_late=True)
def send_push_notification(self, user_id, title, body, data=None, notification_type=""):
    try:
        from apps.notifications.models import DeviceToken
        from apps.notifications.services import DeviceTokenService, NotificationService
        from apps.users.models import User

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            logger.warning("[notification_tasks] user not found user_id=%s", user_id)
            return

        NotificationService.create(
            recipient=user,
            notification_type=notification_type,
            title=title,
            body=body,
            data=data or {},
        )

        if not NotificationService.push_allowed(user, notification_type):
            logger.info(
                "[notification_tasks] push disabled type=%s user=%s",
                notification_type,
                user_id,
            )
            return

        tokens = DeviceTokenService.get_tokens(user)
        if not tokens:
            logger.info("[notification_tasks] no device tokens user=%s", user_id)
            return

        if messaging is None:
            logger.warning(
                "[notification_tasks] firebase_admin not installed — push skipped"
            )
            return

        message = messaging.MulticastMessage(
            notification=messaging.Notification(title=title, body=body),
            data={k: str(v) for k, v in (data or {}).items()},
            tokens=tokens,
        )
        response = messaging.send_each_for_multicast(message)

        for idx, resp in enumerate(response.responses):
            if not resp.success:
                failed_token = tokens[idx]
                error_code = getattr(resp.exception, "code", None)
                if error_code in (
                    "registration-token-not-registered",
                    "invalid-registration-token",
                ):
                    logger.info(
                        "[notification_tasks] removing invalid token=%s", failed_token
                    )
                    DeviceToken.objects.filter(token=failed_token).delete()
                else:
                    logger.error(
                        "[notification_tasks] FCM failed token=%s error=%s",
                        failed_token,
                        resp.exception,
                    )

        logger.info(
            "[notification_tasks] sent=%d failed=%d user=%s",
            response.success_count,
            response.failure_count,
            user_id,
        )

    except Exception as exc:
        logger.error(
            "[notification_tasks] send_push_notification failed: user=%s error=%s",
            user_id,
            exc,
        )
        raise self.retry(exc=exc)
