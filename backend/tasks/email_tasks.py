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
    ("INVITATION", "pt_BR"): "BREVO_INVITATION_TEMPLATE_ID_PT_BR",
    ("EXPENSE_NOTIFICATION", "pt_BR"): "BREVO_EXPENSE_NOTIFICATION_TEMPLATE_ID_PT_BR",
    ("SETTLEMENT_RECORDED", "pt_BR"): "BREVO_SETTLEMENT_RECORDED_TEMPLATE_ID_PT_BR",
    ("SETTLEMENT_CONFIRMED", "pt_BR"): "BREVO_SETTLEMENT_CONFIRMED_TEMPLATE_ID_PT_BR",
    ("WEEKLY_DIGEST", "pt_BR"): "BREVO_WEEKLY_DIGEST_TEMPLATE_ID_PT_BR",
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


@shared_task(bind=True, max_retries=3, default_retry_delay=60, task_acks_late=True)
def send_invitation_email(self, inviter_id: str, invited_email: str, invite_token: str):
    try:
        from apps.users.models import User

        inviter = User.objects.get(id=inviter_id)
        frontend_url = getattr(settings, "FRONTEND_URL", "https://app.rachae.app")
        join_url = f"{frontend_url}/invite?token={invite_token}"
        template_id = _get_template_id("INVITATION", inviter.preferred_locale)
        client = get_brevo_client()
        client.send_transac_email(
            SendSmtpEmail(
                to=[{"email": invited_email}],
                template_id=template_id,
                params={
                    "inviter_name": inviter.display_name,
                    "join_url": join_url,
                },
            )
        )
        logger.info(
            "[email_tasks] send_invitation_email: sent to=%s inviter=%s",
            invited_email,
            inviter_id,
        )
    except Exception as exc:
        logger.error(
            "[email_tasks] send_invitation_email failed: invited=%s error=%s",
            invited_email,
            exc,
        )
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=60, task_acks_late=True)
def send_expense_notification(self, user_id: str, expense_id: str):
    try:
        from apps.users.models import User
        from apps.expenses.models import Expense, Split

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

        split = Split.objects.filter(expense=expense, user=user).first()
        your_share = str(split.amount_owed) if split else None
        template_id = _get_template_id("EXPENSE_NOTIFICATION", user.preferred_locale)
        client = get_brevo_client()
        client.send_transac_email(
            SendSmtpEmail(
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
        client = get_brevo_client()

        for recipient in (payer, receiver):
            template_id = _get_template_id(event, recipient.preferred_locale)
            client.send_transac_email(
                SendSmtpEmail(
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


@shared_task(bind=True, max_retries=3, default_retry_delay=120, task_acks_late=True)
def send_weekly_digest(self):
    try:
        from apps.users.models import User
        from apps.ledger.services import LedgerService

        users = (
            User.objects.filter(
                is_deleted=False,
                group_memberships__group__is_deleted=False,
            ).distinct()
        )

        client = get_brevo_client()
        sent = errors = 0

        for user in users:
            try:
                balance_data = LedgerService.net_balances_for_user(user)
                template_id = _get_template_id("WEEKLY_DIGEST", user.preferred_locale)
                client.send_transac_email(
                    SendSmtpEmail(
                        to=[{"email": user.email, "name": user.display_name}],
                        template_id=template_id,
                        params={
                            "recipient_name": user.display_name,
                            "total_you_owe": balance_data["total_you_owe"],
                            "total_owed_to_you": balance_data["total_owed_to_you"],
                            "net": balance_data["net"],
                            "currency": balance_data["currency"],
                            "group_count": len(balance_data["by_group"]),
                            "groups": balance_data["by_group"],
                        },
                    )
                )
                sent += 1
            except Exception as user_exc:
                logger.error(
                    "[email_tasks] send_weekly_digest: failed for user=%s error=%s",
                    user.id,
                    user_exc,
                )
                errors += 1

        logger.info("[email_tasks] send_weekly_digest complete: sent=%d errors=%d", sent, errors)
    except Exception as exc:
        logger.error("[email_tasks] send_weekly_digest top-level failure: %s", exc)
        raise self.retry(exc=exc)
