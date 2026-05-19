import uuid
from unittest.mock import MagicMock

import pytest

from apps.users.models import User


pytestmark = pytest.mark.django_db


def test_get_status_returns_correct_shape(subscribed_user):
    from apps.ads.services import AdsService

    status = AdsService.get_status(subscribed_user)

    assert "is_ad_free" in status
    assert "subscription_status" in status
    assert "plan_expires_at" in status
    assert "plan_type" in status
    assert "stripe_portal_available" in status
    assert status["is_ad_free"] is True
    assert status["stripe_portal_available"] is True


def test_create_checkout_session_uses_monthly_price(settings, mock_stripe_api):
    from apps.ads.services import AdsService

    settings.STRIPE_PRICE_MONTHLY = "price_m_test"
    settings.FRONTEND_URL = "https://app.rachae.app"
    mock_stripe_api.checkout.Session.create.return_value = MagicMock(url="https://checkout.stripe.com/x")

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="test@rachae.app",
        display_name="Test",
        stripe_customer_id="cus_test123",
        is_ad_free=False,
    )

    result = AdsService.create_checkout_session(user, plan="monthly")

    assert result["checkout_url"].startswith("https://checkout.stripe.com")
    call_kwargs = mock_stripe_api.checkout.Session.create.call_args[1]
    assert call_kwargs["line_items"][0]["price"] == "price_m_test"
    assert call_kwargs["mode"] == "subscription"


def test_create_checkout_session_success_url_uses_frontend_url(settings, mock_stripe_api):
    from apps.ads.services import AdsService

    settings.STRIPE_PRICE_MONTHLY = "price_m"
    settings.FRONTEND_URL = "https://app.rachae.app"
    mock_stripe_api.checkout.Session.create.return_value = MagicMock(url="https://x")

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="url@rachae.app",
        display_name="URL",
        stripe_customer_id="cus_url",
    )

    AdsService.create_checkout_session(user, plan="monthly")

    call_kwargs = mock_stripe_api.checkout.Session.create.call_args[1]
    assert "rachae.app" in call_kwargs["success_url"]
    assert "rachae.app" in call_kwargs["cancel_url"]


def test_create_portal_session_passes_customer_id(settings, mock_stripe_api):
    from apps.ads.services import AdsService

    settings.FRONTEND_URL = "https://app.rachae.app"
    mock_stripe_api.billing_portal.Session.create.return_value = MagicMock(url="https://billing.stripe.com/p")

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="portal@rachae.app",
        display_name="Portal",
        stripe_customer_id="cus_portal123",
        is_ad_free=True,
    )

    result = AdsService.create_portal_session(user)

    assert "portal_url" in result
    call_kwargs = mock_stripe_api.billing_portal.Session.create.call_args[1]
    assert call_kwargs["customer"] == "cus_portal123"


def test_apply_subscription_event_sets_correct_fields(settings):
    from apps.ads.services import AdsService

    settings.STRIPE_PRICE_MONTHLY = "price_m_999"
    settings.STRIPE_PRICE_YEARLY = "price_y_999"

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="event@rachae.app",
        display_name="Event",
        stripe_customer_id="cus_event",
        is_ad_free=False,
    )

    subscription_obj = {
        "customer": "cus_event",
        "status": "active",
        "current_period_end": 9999999999,
        "items": {"data": [{"price": {"id": "price_m_999"}}]},
    }

    AdsService.apply_subscription_event(subscription_obj, grant=True)
    user.refresh_from_db()

    assert user.is_ad_free is True
    assert user.subscription_status == "active"
    assert user.plan_type == "monthly"
    assert user.plan_expires_at is not None

def test_apply_subscription_event_unknown_customer_no_op(settings):
    from apps.ads.services import AdsService

    settings.STRIPE_PRICE_MONTHLY = "price_m_999"
    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="unknowncus@rachae.app",
        display_name="U",
        stripe_customer_id="cus_known",
        is_ad_free=False,
    )
    subscription_obj = {
        "customer": "cus_unknown_xyz",
        "status": "active",
        "current_period_end": 9999999999,
        "items": {"data": [{"price": {"id": "price_m_999"}}]},
    }

    AdsService.apply_subscription_event(subscription_obj, grant=True)
    user.refresh_from_db()
    assert user.is_ad_free is False


def test_apply_subscription_event_missing_customer_id_no_op(settings):
    from apps.ads.services import AdsService

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="nocust@rachae.app",
        display_name="U",
        stripe_customer_id="cus_x",
        is_ad_free=False,
    )
    subscription_obj = {
        "status": "active",
        "current_period_end": 9999999999,
        "items": {"data": [{"price": {"id": settings.STRIPE_PRICE_MONTHLY}}]},
    }

    AdsService.apply_subscription_event(subscription_obj, grant=True)
    user.refresh_from_db()
    assert user.is_ad_free is False

