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
    with patch("apps.ads.views.AdsService.process_stripe_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/stripe-webhook/",
            data=b'{"type":"test"}',
            content_type="application/json",
            HTTP_STRIPE_SIGNATURE="t=123,v1=abc",
        )

    assert response.status_code == 200
    assert response.json() == {"received": True}
    mock_process.assert_called_once()


def test_webhook_alias_ads_webhook_path_returns_200(api_client):
    with patch("apps.ads.views.AdsService.process_stripe_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/webhook/",
            data=b'{"type":"test"}',
            content_type="application/json",
            HTTP_STRIPE_SIGNATURE="t=123,v1=abc",
        )

    assert response.status_code == 200
    mock_process.assert_called_once()


def test_webhook_processes_raw_payload_synchronously(api_client):
    with patch("apps.ads.views.AdsService.process_stripe_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/stripe-webhook/",
            data=b'{"type":"customer.subscription.created"}',
            content_type="application/json",
            HTTP_STRIPE_SIGNATURE="t=123,v1=abc",
        )

    assert response.status_code == 200
    mock_process.assert_called_once()
    call_args = mock_process.call_args[0]
    assert b"customer.subscription.created" in call_args[0]
    assert call_args[1] == "t=123,v1=abc"


def test_webhook_does_not_require_jwt_auth(api_client):
    with patch("apps.ads.views.AdsService.process_stripe_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/stripe-webhook/",
            data=b"{}",
            content_type="application/json",
        )

    assert response.status_code == 200
    mock_process.assert_called_once()


def test_revenuecat_webhook_returns_200_immediately(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = "rc_secret"
    payload = {
        "event": {
            "type": "INITIAL_PURCHASE",
            "app_user_id": str(uuid.uuid4()),
        },
    }
    with patch("apps.ads.views.AdsService.process_rc_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data=payload,
            format="json",
            HTTP_AUTHORIZATION="Bearer rc_secret",
        )

    assert response.status_code == 200
    assert response.json() == {"received": True}
    mock_process.assert_called_once()


def test_revenuecat_webhook_401_when_secret_not_configured(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = ""
    with patch("apps.ads.views.AdsService.process_rc_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data={"event": {"type": "INITIAL_PURCHASE"}},
            format="json",
        )

    assert response.status_code == 401
    mock_process.assert_not_called()


def test_revenuecat_webhook_401_when_secret_mismatch(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = "rc_expected"
    with patch("apps.ads.views.AdsService.process_rc_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data={"event": {}},
            format="json",
            HTTP_AUTHORIZATION="Bearer wrong",
        )

    assert response.status_code == 401
    mock_process.assert_not_called()


def test_revenuecat_webhook_accepts_bearer_secret(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = "rc_secret"
    with patch("apps.ads.views.AdsService.process_rc_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data={"event": {"type": "TEST"}},
            format="json",
            HTTP_AUTHORIZATION="Bearer rc_secret",
        )

    assert response.status_code == 200
    mock_process.assert_called_once()


def test_revenuecat_webhook_does_not_require_jwt_auth(api_client, settings):
    settings.REVENUECAT_WEBHOOK_SECRET = "rc_secret"
    with patch("apps.ads.views.AdsService.process_rc_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data={"event": {"type": "UNKNOWN"}},
            format="json",
            HTTP_AUTHORIZATION="Bearer rc_secret",
        )

    assert response.status_code == 200
    mock_process.assert_called_once()


def test_sync_endpoint_returns_status_without_api_key_configured(auth_client, settings):
    settings.REVENUECAT_API_KEY = ""

    response = auth_client.post("/api/v1/ads/sync/")

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["is_ad_free"] is False


def test_sync_endpoint_requires_authentication(api_client):
    response = api_client.post("/api/v1/ads/sync/")
    assert response.status_code in (401, 403)


def test_sync_endpoint_applies_active_entitlement(auth_client, settings):
    settings.REVENUECAT_API_KEY = "rc_secret_key"
    user = auth_client.handler._force_user

    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {
        "subscriber": {
            "entitlements": {
                "ad_free": {
                    "product_identifier": "com.cau393.rachae.adfree.monthly",
                    "expires_date": "2999-01-01T00:00:00Z",
                },
            },
        },
    }

    with patch("apps.ads.services.requests.get", return_value=mock_response) as mock_get:
        response = auth_client.post("/api/v1/ads/sync/")

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["is_ad_free"] is True
    assert data["plan_type"] == "monthly"
    mock_get.assert_called_once()
    call_kwargs = mock_get.call_args[1]
    assert call_kwargs["headers"]["Authorization"] == "Bearer rc_secret_key"

    user.refresh_from_db()
    assert user.is_ad_free is True


def test_sync_endpoint_expired_entitlement_ignored_with_stripe_customer(
    auth_client_subscribed, settings
):
    settings.REVENUECAT_API_KEY = "rc_secret_key"

    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {
        "subscriber": {
            "entitlements": {
                "ad_free": {
                    "product_identifier": "com.cau393.rachae.adfree.monthly",
                    "expires_date": "2000-01-01T00:00:00Z",
                },
            },
        },
    }

    with patch("apps.ads.services.requests.get", return_value=mock_response):
        response = auth_client_subscribed.post("/api/v1/ads/sync/")

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["is_ad_free"] is True
    assert data["subscription_status"] == "active"


def test_sync_endpoint_revokes_expired_entitlement_without_stripe_customer(
    auth_client, settings
):
    settings.REVENUECAT_API_KEY = "rc_secret_key"
    user = auth_client.handler._force_user
    user.is_ad_free = True
    user.subscription_status = "active"
    user.plan_type = "monthly"
    user.save()

    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {
        "subscriber": {
            "entitlements": {
                "ad_free": {
                    "product_identifier": "com.cau393.rachae.adfree.monthly",
                    "expires_date": "2000-01-01T00:00:00Z",
                },
            },
        },
    }

    with patch("apps.ads.services.requests.get", return_value=mock_response):
        response = auth_client.post("/api/v1/ads/sync/")

    assert response.status_code == 200
    data = response.json()["data"]
    assert data["is_ad_free"] is False
    assert data["subscription_status"] == "expired"


def test_sync_endpoint_no_entitlement_returns_current_status(auth_client, settings):
    settings.REVENUECAT_API_KEY = "rc_secret_key"

    mock_response = MagicMock()
    mock_response.raise_for_status = MagicMock()
    mock_response.json.return_value = {"subscriber": {"entitlements": {}}}

    with patch("apps.ads.services.requests.get", return_value=mock_response):
        response = auth_client.post("/api/v1/ads/sync/")

    assert response.status_code == 200
    assert response.json()["data"]["is_ad_free"] is False


def test_sync_endpoint_api_error_returns_current_status(auth_client, settings):
    settings.REVENUECAT_API_KEY = "rc_secret_key"

    with patch("apps.ads.services.requests.get", side_effect=Exception("network down")):
        response = auth_client.post("/api/v1/ads/sync/")

    assert response.status_code == 200
    assert response.json()["data"]["is_ad_free"] is False



def _rc_signature(raw_body: bytes, secret: str, timestamp: int) -> str:
    import hashlib
    import hmac as hmac_lib

    digest = hmac_lib.new(
        secret.encode(), f"{timestamp}.".encode() + raw_body, hashlib.sha256
    ).hexdigest()
    return f"t={timestamp},v1={digest}"


def test_revenuecat_webhook_accepts_valid_hmac_signature(api_client, settings):
    import time

    settings.REVENUECAT_WEBHOOK_SECRET = "rc_signing_secret"
    raw = b'{"event": {"type": "TEST"}}'
    header = _rc_signature(raw, "rc_signing_secret", int(time.time()))

    with patch("apps.ads.views.AdsService.process_rc_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data=raw,
            content_type="application/json",
            HTTP_X_REVENUECAT_WEBHOOK_SIGNATURE=header,
        )

    assert response.status_code == 200
    mock_process.assert_called_once()


def test_revenuecat_webhook_rejects_bad_hmac_signature(api_client, settings):
    import time

    settings.REVENUECAT_WEBHOOK_SECRET = "rc_signing_secret"
    raw = b'{"event": {"type": "TEST"}}'
    header = _rc_signature(raw, "wrong_secret", int(time.time()))

    with patch("apps.ads.views.AdsService.process_rc_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data=raw,
            content_type="application/json",
            HTTP_X_REVENUECAT_WEBHOOK_SIGNATURE=header,
        )

    assert response.status_code == 401
    mock_process.assert_not_called()


def test_revenuecat_webhook_rejects_stale_hmac_timestamp(api_client, settings):
    import time

    settings.REVENUECAT_WEBHOOK_SECRET = "rc_signing_secret"
    raw = b'{"event": {"type": "TEST"}}'
    header = _rc_signature(raw, "rc_signing_secret", int(time.time()) - 3600)

    with patch("apps.ads.views.AdsService.process_rc_event") as mock_process:
        response = api_client.post(
            "/api/v1/ads/revenuecat-webhook/",
            data=raw,
            content_type="application/json",
            HTTP_X_REVENUECAT_WEBHOOK_SIGNATURE=header,
        )

    assert response.status_code == 401
    mock_process.assert_not_called()
