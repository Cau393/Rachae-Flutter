import base64
import uuid
from unittest.mock import MagicMock, patch

import pytest
import stripe

from tasks.ledger_tasks import run_debt_simplification_all_groups
from tasks.notification_tasks import send_push_notification
from tasks.revenuecat_tasks import process_rc_webhook
from tasks.stripe_tasks import create_stripe_customer, process_stripe_webhook


@pytest.mark.django_db
def test_send_push_notification_delay_completes_without_error():
    result = send_push_notification.delay(str(uuid.uuid4()), "T", "B")
    assert result.get() is None


def test_process_stripe_webhook_invalid_signature_returns_none(settings):
    settings.STRIPE_WEBHOOK_SECRET = "whsec_test"

    error = stripe.error.SignatureVerificationError(
        "Invalid signature",
        "sig_header",
    )
    with patch("stripe.Webhook.construct_event", side_effect=error):
        result = process_stripe_webhook.apply(
            args=[base64.b64encode(b"{}").decode("ascii"), "sig_header"],
            throw=True,
        )

    assert result.get() is None


def test_create_stripe_customer_delay_completes_without_error():
    result = create_stripe_customer.delay(str(uuid.uuid4()))
    assert result.get() is None


def test_process_rc_webhook_delay_completes_without_error():
    result = process_rc_webhook.delay({"event": {"type": "IGNORED"}})
    assert result.get() is None


@pytest.mark.django_db
def test_run_debt_simplification_all_groups_dispatches_each_group():
    group_ids = [uuid.uuid4(), uuid.uuid4(), uuid.uuid4()]
    mock_values_list = MagicMock(return_value=group_ids)
    mock_filter = MagicMock()
    mock_filter.values_list = mock_values_list

    with patch("apps.groups.models.Group.objects.filter", return_value=mock_filter), patch(
        "tasks.ledger_tasks.run_debt_simplification.delay"
    ) as mock_delay:
        run_debt_simplification_all_groups.delay().get()

    assert mock_delay.call_count == 3
    mock_delay.assert_any_call(str(group_ids[0]))
    mock_delay.assert_any_call(str(group_ids[1]))
    mock_delay.assert_any_call(str(group_ids[2]))
