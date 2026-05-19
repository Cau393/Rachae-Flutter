import base64
from unittest.mock import MagicMock

import pytest


def _stripe_payload_b64(data: bytes = b"payload") -> str:
    """Matches StripeWebhookView: body is base64-encoded for Celery JSON transport."""
    return base64.b64encode(data).decode("ascii")


def _make_subscription_event(
    event_type,
    customer_id,
    status,
    price_id,
    period_end=9999999999,
) -> dict:
    return {
        "type": event_type,
        "data": {
            "object": {
                "customer": customer_id,
                "status": status,
                "current_period_end": period_end,
                "items": {"data": [{"price": {"id": price_id}}]},
            }
        },
    }


@pytest.mark.django_db
def test_process_webhook_subscription_created_sets_ad_free(
    settings,
    stripe_user,
    mock_stripe,
):
    settings.STRIPE_PRICE_MONTHLY = "price_monthly_123"
    event = _make_subscription_event(
        "customer.subscription.created",
        customer_id=stripe_user.stripe_customer_id,
        status="active",
        price_id="price_monthly_123",
    )
    mock_stripe.Webhook.construct_event.return_value = event

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    stripe_user.refresh_from_db()
    assert stripe_user.is_ad_free is True
    assert stripe_user.subscription_status == "active"
    assert stripe_user.plan_type == "monthly"
    assert stripe_user.plan_expires_at is not None


@pytest.mark.django_db
def test_process_webhook_subscription_created_yearly_sets_plan_type(
    settings,
    stripe_user,
    mock_stripe,
):
    settings.STRIPE_PRICE_YEARLY = "price_yearly_456"
    event = _make_subscription_event(
        "customer.subscription.created",
        customer_id=stripe_user.stripe_customer_id,
        status="active",
        price_id="price_yearly_456",
    )
    mock_stripe.Webhook.construct_event.return_value = event

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    stripe_user.refresh_from_db()
    assert stripe_user.plan_type == "yearly"


@pytest.mark.django_db
def test_process_webhook_subscription_deleted_clears_ad_free(
    stripe_user_subscribed,
    mock_stripe,
):
    event = _make_subscription_event(
        "customer.subscription.deleted",
        customer_id=stripe_user_subscribed.stripe_customer_id,
        status="canceled",
        price_id="price_monthly_test",
    )
    mock_stripe.Webhook.construct_event.return_value = event

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    stripe_user_subscribed.refresh_from_db()
    assert stripe_user_subscribed.is_ad_free is False
    assert stripe_user_subscribed.subscription_status == "canceled"
    assert stripe_user_subscribed.plan_expires_at is None
    assert stripe_user_subscribed.plan_type is None


@pytest.mark.django_db
def test_process_webhook_subscription_updated_past_due_revokes_ad_free(
    stripe_user_subscribed,
    mock_stripe,
):
    event = _make_subscription_event(
        "customer.subscription.updated",
        customer_id=stripe_user_subscribed.stripe_customer_id,
        status="past_due",
        price_id="price_monthly_test",
    )
    mock_stripe.Webhook.construct_event.return_value = event

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    stripe_user_subscribed.refresh_from_db()
    assert stripe_user_subscribed.is_ad_free is False
    assert stripe_user_subscribed.subscription_status == "past_due"


@pytest.mark.django_db
def test_process_webhook_subscription_updated_trialing_grants_ad_free(
    stripe_user,
    mock_stripe,
):
    event = _make_subscription_event(
        "customer.subscription.updated",
        customer_id=stripe_user.stripe_customer_id,
        status="trialing",
        price_id="price_monthly_test",
    )
    mock_stripe.Webhook.construct_event.return_value = event

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    stripe_user.refresh_from_db()
    assert stripe_user.is_ad_free is True


@pytest.mark.django_db
def test_process_webhook_unknown_event_type_is_ignored(mock_stripe):
    mock_stripe.Webhook.construct_event.return_value = {
        "type": "payment_intent.succeeded",
        "data": {"object": {}},
    }

    from tasks.stripe_tasks import process_stripe_webhook

    result = process_stripe_webhook.apply(args=[_stripe_payload_b64(), "sig_header"])
    assert result.state != "FAILURE"


@pytest.mark.django_db
def test_process_webhook_invalid_signature_does_not_retry(mock_stripe):
    import stripe as stripe_lib
    from tasks.stripe_tasks import process_stripe_webhook

    mock_stripe.Webhook.construct_event.side_effect = stripe_lib.error.SignatureVerificationError(
        "bad sig",
        "sig_header",
    )

    result = process_stripe_webhook.apply(args=[_stripe_payload_b64(), "bad_sig"])
    assert result.state != "FAILURE"


@pytest.mark.django_db
def test_process_webhook_retries_on_stripe_api_error(mock_stripe):
    import stripe as stripe_lib
    from tasks.stripe_tasks import process_stripe_webhook

    mock_stripe.Webhook.construct_event.side_effect = stripe_lib.error.StripeError("API down")

    with pytest.raises(Exception):
        process_stripe_webhook.apply(args=[_stripe_payload_b64(), "sig_header"])


@pytest.mark.django_db
def test_create_stripe_customer_saves_customer_id(
    user_without_stripe,
    mock_stripe,
):
    mock_stripe.Customer.create.return_value = MagicMock(id="cus_newid123")

    from tasks.stripe_tasks import create_stripe_customer

    create_stripe_customer(str(user_without_stripe.id))
    user_without_stripe.refresh_from_db()

    assert user_without_stripe.stripe_customer_id == "cus_newid123"


@pytest.mark.django_db
def test_create_stripe_customer_is_idempotent(stripe_user, mock_stripe):
    from tasks.stripe_tasks import create_stripe_customer

    create_stripe_customer(str(stripe_user.id))
    mock_stripe.Customer.create.assert_not_called()


@pytest.mark.django_db
def test_create_stripe_customer_retries_on_stripe_error(
    user_without_stripe,
    mock_stripe,
):
    import stripe as stripe_lib
    from tasks.stripe_tasks import create_stripe_customer

    mock_stripe.Customer.create.side_effect = stripe_lib.error.StripeError("timeout")

    with pytest.raises(Exception):
        create_stripe_customer.apply(args=[str(user_without_stripe.id)])


@pytest.mark.django_db
def test_process_webhook_checkout_session_completed_binds_customer(
    user_without_stripe,
    mock_stripe,
):
    event = {
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "client_reference_id": str(user_without_stripe.id),
                "customer": "cus_from_checkout",
            }
        },
    }
    mock_stripe.Webhook.construct_event.return_value = event

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    user_without_stripe.refresh_from_db()
    assert user_without_stripe.stripe_customer_id == "cus_from_checkout"
    mock_stripe.Subscription.retrieve.assert_not_called()


@pytest.mark.django_db
def test_process_webhook_checkout_session_completed_syncs_subscription_entitlements(
    user_without_stripe,
    mock_stripe,
    settings,
):
    settings.STRIPE_PRICE_MONTHLY = "price_monthly_test"
    event = {
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "client_reference_id": str(user_without_stripe.id),
                "customer": "cus_from_checkout",
                "subscription": "sub_after_checkout",
            }
        },
    }
    mock_stripe.Webhook.construct_event.return_value = event
    mock_stripe.Subscription.retrieve.return_value = {
        "customer": "cus_from_checkout",
        "status": "active",
        "current_period_end": 9999999999,
        "items": {"data": [{"price": {"id": "price_monthly_test"}}]},
    }

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    mock_stripe.Subscription.retrieve.assert_called_once_with(
        "sub_after_checkout",
        expand=["items.data.price"],
    )
    user_without_stripe.refresh_from_db()
    assert user_without_stripe.stripe_customer_id == "cus_from_checkout"
    assert user_without_stripe.is_ad_free is True
    assert user_without_stripe.subscription_status == "active"


@pytest.mark.django_db
def test_process_webhook_checkout_completed_thin_payload_expands_session(
    user_without_stripe,
    mock_stripe,
    settings,
):
    """Webhook session object may omit subscription; expand via Session.retrieve."""
    settings.STRIPE_PRICE_MONTHLY = "price_monthly_test"
    sid = "cs_test_expand"
    event = {
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "id": sid,
                "mode": "subscription",
                "client_reference_id": str(user_without_stripe.id),
                "customer": "cus_from_checkout",
            }
        },
    }
    mock_stripe.Webhook.construct_event.return_value = event
    mock_stripe.checkout.Session.retrieve.return_value = {
        "id": sid,
        "mode": "subscription",
        "client_reference_id": str(user_without_stripe.id),
        "customer": "cus_from_checkout",
        "subscription": {"id": "sub_from_expand", "object": "subscription"},
    }
    mock_stripe.Subscription.retrieve.return_value = {
        "customer": "cus_from_checkout",
        "status": "active",
        "current_period_end": 9999999999,
        "items": {"data": [{"price": {"id": "price_monthly_test"}}]},
    }

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    mock_stripe.checkout.Session.retrieve.assert_called_once_with(
        sid,
        expand=["customer", "subscription", "payment_intent.customer"],
    )
    user_without_stripe.refresh_from_db()
    assert user_without_stripe.is_ad_free is True


@pytest.mark.django_db
def test_process_webhook_checkout_session_completed_missing_ref_skipped(
    user_without_stripe,
    mock_stripe,
):
    event = {
        "type": "checkout.session.completed",
        "data": {
            "object": {
                "client_reference_id": None,
                "customer": "cus_x",
            }
        },
    }
    mock_stripe.Webhook.construct_event.return_value = event

    from tasks.stripe_tasks import process_stripe_webhook

    process_stripe_webhook(_stripe_payload_b64(), "sig_header")

    user_without_stripe.refresh_from_db()
    assert user_without_stripe.stripe_customer_id is None


@pytest.mark.django_db
def test_process_webhook_subscription_unknown_customer_returns_cleanly(
    user_without_stripe,
    mock_stripe,
    settings,
):
    settings.STRIPE_PRICE_MONTHLY = "price_monthly_test"
    event = _make_subscription_event(
        "customer.subscription.created",
        customer_id="cus_never_bound",
        status="active",
        price_id="price_monthly_test",
    )
    mock_stripe.Webhook.construct_event.return_value = event

    from tasks.stripe_tasks import process_stripe_webhook

    result = process_stripe_webhook.apply(args=[_stripe_payload_b64(), "sig_header"])
    assert result.state != "FAILURE"

    user_without_stripe.refresh_from_db()
    assert user_without_stripe.is_ad_free is False

