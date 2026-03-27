import logging
import sib_api_v3_sdk
from celery import shared_task
from django.conf import settings
from sib_api_v3_sdk import SendSmtpEmail

logger = logging.getLogger(__name__)


def get_brevo_client() -> sib_api_v3_sdk.TransactionalEmailsApi:
    configuration = sib_api_v3_sdk.Configuration()
    configuration.api_key["api-key"] = settings.BREVO_API_KEY
    return sib_api_v3_sdk.TransactionalEmailsApi(sib_api_v3_sdk.ApiClient(configuration))


_TEMPLATE_MAP: dict[tuple[str, str], str] = {
    ("EXPENSE_NOTIFICATION", "pt_BR"): "BREVO_EXPENSE_NOTIFICATION_TEMPLATE_ID_PT_BR",
    ("SETTLEMENT_RECORDED", "pt_BR"): "BREVO_SETTLEMENT_RECORDED_TEMPLATE_ID_PT_BR",
    ("SETTLEMENT_CONFIRMED", "pt_BR"): "BREVO_SETTLEMENT_CONFIRMED_TEMPLATE_ID_PT_BR",
}

_DEFAULT_LOCALE = "pt_BR"


def _get_template_id(event_name: str, locale: str) -> int:
    settings_key = _TEMPLATE_MAP.get((event_name, locale)) or _TEMPLATE_MAP.get(
        (event_name, _DEFAULT_LOCALE)
    )
    if not settings_key:
        raise ValueError(
            f"No Brevo template configured for event='{event_name}' locale='{locale}'. "
            "Add an entry to _TEMPLATE_MAP and a BREVO_*_PT_BR constant in settings."
        )

    template_id = getattr(settings, settings_key, None)
    if not template_id:
        raise ValueError(
            f"Settings key '{settings_key}' is missing or zero. "
            "Set it in settings and in environment variables."
        )
    return int(template_id)


def _optional_brevo_sender() -> dict | None:
    email = (getattr(settings, "EMAIL_FROM", "") or "").strip()
    if not email:
        return None
    name = (getattr(settings, "EMAIL_FROM_NAME", "") or "").strip()
    out: dict = {"email": email}
    if name:
        out["name"] = name
    return out


def _brevo_api_key_configured() -> bool:
    return bool((getattr(settings, "BREVO_API_KEY", "") or "").strip())


def _stringify_brevo_params(params: dict) -> dict:
    """Brevo transactional templates expect string params; nulls often break the API."""
    out: dict = {}
    for k, v in params.items():
        if v is None:
            out[k] = ""
        elif isinstance(v, bool):
            out[k] = v
        else:
            out[k] = str(v)
    return out


def _send_transac_template(
    client: sib_api_v3_sdk.TransactionalEmailsApi,
    *,
    to: list,
    template_id: int,
    params: dict,
) -> None:
    from sib_api_v3_sdk.rest import ApiException

    payload: dict = {
        "to": to,
        "template_id": template_id,
        "params": _stringify_brevo_params(params),
    }
    sender = _optional_brevo_sender()
    if sender:
        payload["sender"] = sender
    try:
        client.send_transac_email(SendSmtpEmail(**payload))
    except ApiException as exc:
        logger.error(
            "[email_tasks] Brevo ApiException status=%s reason=%s body=%s",
            getattr(exc, "status", None),
            getattr(exc, "reason", None),
            getattr(exc, "body", None),
        )
        raise


@shared_task(bind=True, max_retries=3, default_retry_delay=60, task_acks_late=True)
def send_expense_notification(self, user_id: str, expense_id: str):
    try:
        from apps.users.models import User
        from apps.expenses.models import Expense
        from apps.splits.models import Split

        user = User.objects.get(id=user_id)
        expense = Expense.objects.select_related("paid_by", "group", "created_by").get(
            id=expense_id
        )

        if str(expense.created_by_id) == str(user.id):
            logger.debug(
                "[email_tasks] send_expense_notification: skipping creator user=%s",
                user_id,
            )
            return

        if not _brevo_api_key_configured():
            logger.warning(
                "[email_tasks] send_expense_notification: BREVO_API_KEY missing, skip user=%s",
                user_id,
            )
            return

        split = Split.objects.filter(expense=expense, user=user).first()
        your_share = str(split.amount_owed) if split else None
        template_id = _get_template_id("EXPENSE_NOTIFICATION", user.preferred_locale)
        client = get_brevo_client()
        _send_transac_template(
            client,
            to=[{"email": user.email, "name": user.display_name}],
            template_id=template_id,
            params={
                "recipient_name": user.display_name,
                "expense_desc": expense.description,
                "amount": str(expense.amount_in_group_currency),
                "currency": expense.group.currency if expense.group else expense.currency,
                "paid_by_name": expense.paid_by.display_name,
                "group_name": expense.group.name if expense.group else None,
                "category": expense.category,
                "your_share": your_share,
                "expense_date": str(expense.expense_date),
            },
        )
        logger.info(
            "[email_tasks] send_expense_notification: sent user=%s expense=%s",
            user_id,
            expense_id,
        )
    except Exception as exc:
        logger.error(
            "[email_tasks] send_expense_notification failed: user=%s expense=%s error=%s",
            user_id,
            expense_id,
            exc,
        )
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=60, task_acks_late=True)
def send_settlement_confirmation(self, payer_id: str, receiver_id: str, transaction_id: str):
    try:
        from apps.transactions.models import Transaction

        txn = Transaction.objects.select_related("payer", "receiver", "group").get(
            id=transaction_id
        )
        payer = txn.payer
        receiver = txn.receiver

        event = "SETTLEMENT_CONFIRMED" if txn.is_confirmed else "SETTLEMENT_RECORDED"

        if not _brevo_api_key_configured():
            logger.warning(
                "[email_tasks] send_settlement_confirmation: BREVO_API_KEY missing, skip txn=%s",
                transaction_id,
            )
            return

        client = get_brevo_client()

        for recipient in (payer, receiver):
            template_id = _get_template_id(event, recipient.preferred_locale)
            _send_transac_template(
                client,
                to=[{"email": recipient.email, "name": recipient.display_name}],
                template_id=template_id,
                params={
                    "recipient_name": recipient.display_name,
                    "payer_name": payer.display_name,
                    "receiver_name": receiver.display_name,
                    "amount": str(txn.amount),
                    "currency": txn.currency,
                    "group_name": txn.group.name if txn.group else None,
                    "note": txn.note,
                    "is_confirmed": txn.is_confirmed,
                },
            )

        logger.info(
            "[email_tasks] send_settlement_confirmation: event=%s txn=%s",
            event,
            transaction_id,
        )
    except Exception as exc:
        logger.error(
            "[email_tasks] send_settlement_confirmation failed: txn=%s error=%s",
            transaction_id,
            exc,
        )
        raise self.retry(exc=exc)
