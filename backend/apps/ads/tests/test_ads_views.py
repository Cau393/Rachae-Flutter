import base64
import uuid
from unittest.mock import MagicMock, patch

import pytest
from django.test import TestCase as DjangoTestCase


pytestmark = pytest.mark.django_db


def test_status_returns_not_subscribed_defaults(auth_client):
    response = auth_client.get("/api/v1/ads/status/")

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["is_ad_free"] is False
    assert data["subscription_status"] is None
    assert data["plan_expires_at"] is None
    assert data["plan_type"] is None
    assert data["stripe_portal_available"] is False


def test_status_returns_active_subscription(auth_client_subscribed):
    response = auth_client_subscribed.get("/api/v1/ads/status/")

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["is_ad_free"] is True
    assert data["subscription_status"] == "active"
    assert data["plan_type"] == "monthly"
    assert data["plan_expires_at"] is not None
    assert data["stripe_portal_available"] is True


def test_status_requires_authentication(api_client):
    response = api_client.get("/api/v1/ads/status/")
    assert response.status_code in (401, 403)


def test_create_checkout_session_monthly_returns_url(auth_client, settings, mock_stripe_api):
    settings.STRIPE_PRICE_MONTHLY = "price_monthly_test"
    mock_stripe_api.checkout.Session.create.return_value = MagicMock(url="https://checkout.stripe.com/test")

    response = auth_client.post(
        "/api/v1/ads/create-checkout-session/",
        data={"plan": "monthly"},
        format="json",
    )

    assert response.status_code == 201
    assert response.json()["data"]["checkout_url"] == "https://checkout.stripe.com/test"


def test_create_checkout_session_yearly_uses_yearly_price(auth_client, settings, mock_stripe_api):
    settings.STRIPE_PRICE_YEARLY = "price_yearly_test"
    mock_stripe_api.checkout.Session.create.return_value = MagicMock(url="https://checkout.stripe.com/test")

    response = auth_client.post(
        "/api/v1/ads/create-checkout-session/",
        data={"plan": "yearly"},
        format="json",
    )

    assert response.status_code == 201
    call_kwargs = mock_stripe_api.checkout.Session.create.call_args[1]
    assert call_kwargs["line_items"][0]["price"] == "price_yearly_test"


def test_create_checkout_session_does_not_dispatch_create_stripe_customer(
    auth_client, mock_stripe_api, django_user_model,
):
    mock_stripe_api.checkout.Session.create.return_value = MagicMock(url="https://x")
    user = auth_client.handler._force_user
    django_user_model.objects.filter(pk=user.pk).update(stripe_customer_id=None)
    user.refresh_from_db()

    with patch("tasks.stripe_tasks.create_stripe_customer") as mock_task:
        with DjangoTestCase.captureOnCommitCallbacks(execute=True):
            response = auth_client.post(
                "/api/v1/ads/create-checkout-session/",
                data={"plan": "monthly"},
                format="json",
            )

    assert response.status_code == 201
    mock_task.delay.assert_not_called()
    call_kwargs = mock_stripe_api.checkout.Session.create.call_args[1]
    assert call_kwargs["client_reference_id"] == str(user.id)
    assert call_kwargs["customer_email"] == user.email


def test_create_checkout_session_blocks_already_subscribed(auth_client_subscribed):
    response = auth_client_subscribed.post(
        "/api/v1/ads/create-checkout-session/",
        data={"plan": "monthly"},
        format="json",
    )

    assert response.status_code == 400
    assert "already" in response.json()["detail"].lower()


def test_create_checkout_session_invalid_plan_returns_400(auth_client):
    response = auth_client.post(
        "/api/v1/ads/create-checkout-session/",
        data={"plan": "lifetime"},
        format="json",
    )
    assert response.status_code == 400


def test_create_portal_session_returns_url(auth_client_subscribed, settings, mock_stripe_api):
    settings.FRONTEND_URL = "https://app.rachae.app"
    mock_stripe_api.billing_portal.Session.create.return_value = MagicMock(
        url="https://billing.stripe.com/session/test"
    )

    response = auth_client_subscribed.post("/api/v1/ads/create-portal-session/")

    assert response.status_code == 200
    assert response.json()["data"]["portal_url"] == "https://billing.stripe.com/session/test"


def test_create_portal_session_fails_without_stripe_customer(auth_client):
    response = auth_client.post("/api/v1/ads/create-portal-session/")

    assert response.status_code == 400
    assert "subscription" in response.json()["detail"].lower()


def test_webhook_returns_200_immediately(api_client):
    with patch("tasks.stripe_tasks.process_stripe_webhook") as mock_task:
        response = api_client.post(
            "/api/v1/ads/stripe-webhook/",
            data=b'{"type":"test"}',
            content_type="application/json",
            HTTP_STRIPE_SIGNATURE="t=123,v1=abc",
        )

    assert response.status_code == 200
    assert response.json() == {"received": True}
    mock_task.delay.assert_called_once()


def test_webhook_alias_ads_webhook_path_returns_200(api_client):
    with patch("tasks.stripe_tasks.process_stripe_webhook") as mock_task:
        response = api_client.post(
            "/api/v1/ads/webhook/",
            data=b'{"type":"test"}',
            content_type="application/json",
            HTTP_STRIPE_SIGNATURE="t=123,v1=abc",
        )

    assert response.status_code == 200
    mock_task.delay.assert_called_once()


def test_webhook_dispatches_task_with_raw_payload(api_client):
    with patch("tasks.stripe_tasks.process_stripe_webhook") as mock_task:
        response = api_client.post(
            "/api/v1/ads/stripe-webhook/",
            data=b'{"type":"customer.subscription.created"}',
            content_type="application/json",
            HTTP_STRIPE_SIGNATURE="t=123,v1=abc",
        )

    assert response.status_code == 200
    mock_task.delay.assert_called_once()
    call_args = mock_task.delay.call_args[0]
    raw_body = base64.b64decode(call_args[0])
    assert b"customer.subscription.created" in raw_body
    assert call_args[1] == "t=123,v1=abc"


def test_webhook_does_not_require_jwt_auth(api_client):
    with patch("tasks.stripe_tasks.process_stripe_webhook") as mock_task:
        response = api_client.post(
            "/api/v1/ads/stripe-webhook/",
            data=b"{}",
            content_type="application/json",
        )

    assert response.status_code == 200
    mock_task.delay.assert_called_once()


def test_revenuecat_webhook_returns_200_immediately(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = ""
    payload = {
        "event": {
            "type": "INITIAL_PURCHASE",
            "app_user_id": str(uuid.uuid4()),
        },
    }
    with patch("tasks.revenuecat_tasks.process_rc_webhook") as mock_task:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data=payload,
            format="json",
        )

    assert response.status_code == 200
    assert response.json() == {"received": True}
    mock_task.delay.assert_called_once()


def test_revenuecat_webhook_401_when_secret_mismatch(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = "rc_expected"
    with patch("tasks.revenuecat_tasks.process_rc_webhook") as mock_task:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data={"event": {}},
            format="json",
            HTTP_AUTHORIZATION="Bearer wrong",
        )

    assert response.status_code == 401
    mock_task.delay.assert_not_called()


def test_revenuecat_webhook_accepts_bearer_secret(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = "rc_secret"
    with patch("tasks.revenuecat_tasks.process_rc_webhook") as mock_task:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data={"event": {"type": "TEST"}},
            format="json",
            HTTP_AUTHORIZATION="Bearer rc_secret",
        )

    assert response.status_code == 200
    mock_task.delay.assert_called_once()


def test_revenuecat_webhook_does_not_require_jwt_auth(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = ""
    with patch("tasks.revenuecat_tasks.process_rc_webhook") as mock_task:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data={"event": {"type": "UNKNOWN"}},
            format="json",
        )

    assert response.status_code == 200
    mock_task.delay.assert_called_once()
