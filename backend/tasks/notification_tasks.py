import logging

from celery import shared_task

logger = logging.getLogger(__name__)

try:
    from firebase_admin import messaging
except ImportError:
    messaging = None  # Firebase not installed — push silently skipped


def _expense_created_push_copy(
    preferred_locale: str, paid_by_display_name: str, description: str
) -> tuple[str, str]:
    """Short title/body for expense_created push; aligns with MVP locale (pt_BR default)."""
    loc = (preferred_locale or "pt_BR").replace("-", "_").lower()
    raw = (description or "").strip() or "—"
    desc = raw if len(raw) <= 120 else f"{raw[:117]}..."
    if loc.startswith("pt"):
        return "Nova despesa", f"{paid_by_display_name}: {desc}"
    return "New expense", f"{paid_by_display_name}: {desc}"


def _deliver_push_to_user(user, title: str, body: str, data, notification_type: str) -> None:
    """Persist in-app notification, then FCM when allowed and messaging is available."""
    from apps.notifications.models import DeviceToken
    from apps.notifications.services import DeviceTokenService, NotificationService

    user_id = str(user.id)
    data = data or {}

    NotificationService.create(
        recipient=user,
        notification_type=notification_type,
        title=title,
        body=body,
        data=data,
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
        data={k: str(v) for k, v in data.items()},
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


@shared_task(bind=True, max_retries=3, default_retry_delay=30, task_acks_late=True)
def send_push_notification(self, user_id, title, body, data=None, notification_type=""):
    try:
        from apps.users.models import User

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            logger.warning("[notification_tasks] user not found user_id=%s", user_id)
            return

        _deliver_push_to_user(user, title, body, data or {}, notification_type)

    except Exception as exc:
        logger.error(
            "[notification_tasks] send_push_notification failed: user=%s error=%s",
            user_id,
            exc,
        )
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=30, task_acks_late=True)
def send_expense_created_push(self, user_id: str, expense_id: str):
    """In-app + FCM for split participants when an expense is created or splits are replaced."""
    try:
        from apps.expenses.models import Expense
        from apps.users.models import User

        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            logger.warning(
                "[notification_tasks] send_expense_created_push: user not found user_id=%s",
                user_id,
            )
            return

        try:
            expense = Expense.objects.select_related("paid_by", "group", "created_by").get(
                id=expense_id
            )
        except Expense.DoesNotExist:
            logger.warning(
                "[notification_tasks] send_expense_created_push: expense not found expense_id=%s",
                expense_id,
            )
            return

        if str(expense.created_by_id) == str(user.id):
            logger.debug(
                "[notification_tasks] send_expense_created_push: skipping creator user=%s",
                user_id,
            )
            return

        title, body = _expense_created_push_copy(
            user.preferred_locale,
            expense.paid_by.display_name,
            expense.description,
        )
        payload: dict = {
            "expense_id": str(expense.id),
            "type": "expense_created",
        }
        if expense.group_id:
            payload["group_id"] = str(expense.group_id)

        _deliver_push_to_user(user, title, body, payload, "expense_created")
        logger.info(
            "[notification_tasks] send_expense_created_push: user=%s expense=%s",
            user_id,
            expense_id,
        )
    except Exception as exc:
        logger.error(
            "[notification_tasks] send_expense_created_push failed: user=%s expense=%s error=%s",
            user_id,
            expense_id,
            exc,
        )
        raise self.retry(exc=exc)
