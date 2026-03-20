import uuid
from datetime import timedelta
from unittest.mock import patch

import pytest
from django.utils import timezone
from rest_framework.test import APIClient


@pytest.fixture
def mock_stripe_api(settings):
    settings.STRIPE_SECRET_KEY = "sk_test_fake"
    settings.STRIPE_WEBHOOK_SECRET = "whsec_fake"
    settings.STRIPE_PRICE_MONTHLY = "price_monthly_test"
    settings.STRIPE_PRICE_YEARLY = "price_yearly_test"
    with patch("apps.ads.services.stripe") as mock_s:
        import stripe as stripe_lib

        mock_s.error = stripe_lib.error
        yield mock_s


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def subscribed_user(db, django_user_model):
    return django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="subscribed@example.com",
        display_name="Subscribed User",
        stripe_customer_id="cus_sub",
        is_ad_free=True,
        subscription_status="active",
        plan_type="monthly",
        plan_expires_at=timezone.now() + timedelta(days=30),
    )


@pytest.fixture
def auth_client(db, django_user_model):
    user = django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="auth@example.com",
        display_name="Auth User",
    )
    client = APIClient()
    client.force_authenticate(user=user)
    return client


@pytest.fixture
def auth_client_subscribed(subscribed_user):
    client = APIClient()
    client.force_authenticate(user=subscribed_user)
    return client
