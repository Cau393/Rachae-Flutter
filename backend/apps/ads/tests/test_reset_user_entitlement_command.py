import uuid
from datetime import timedelta
from io import StringIO

import pytest
from django.core.management import call_command
from django.core.management.base import CommandError
from django.utils import timezone

from apps.users.models import User


pytestmark = pytest.mark.django_db


def _make_subscribed_user(**overrides):
    defaults = {
        "supabase_uid": uuid.uuid4(),
        "email": "reset-target@example.com",
        "display_name": "Reset Target",
        "stripe_customer_id": "cus_reset_target",
        "is_ad_free": True,
        "subscription_status": "active",
        "plan_type": "monthly",
        "plan_expires_at": timezone.now() + timedelta(days=30),
    }
    defaults.update(overrides)
    return User.objects.create(**defaults)


def test_resets_entitlement_fields_but_preserves_stripe_customer_id_without_flag():
    user = _make_subscribed_user()

    out = StringIO()
    call_command("reset_user_entitlement", user.email, stdout=out)

    user.refresh_from_db()
    assert user.is_ad_free is False
    assert user.subscription_status is None
    assert user.plan_type is None
    assert user.plan_expires_at is None
    assert user.stripe_customer_id == "cus_reset_target"


def test_clears_stripe_customer_id_with_clear_stripe_flag():
    user = _make_subscribed_user(email="reset-stripe@example.com")

    out = StringIO()
    call_command("reset_user_entitlement", user.email, "--clear-stripe", stdout=out)

    user.refresh_from_db()
    assert user.is_ad_free is False
    assert user.subscription_status is None
    assert user.plan_type is None
    assert user.plan_expires_at is None
    assert user.stripe_customer_id is None


def test_looks_up_email_case_insensitively():
    user = _make_subscribed_user(email="mixedcase@example.com")

    out = StringIO()
    call_command("reset_user_entitlement", "MixedCase@Example.com", stdout=out)

    user.refresh_from_db()
    assert user.is_ad_free is False


def test_prints_before_and_after_values():
    user = _make_subscribed_user(email="printed@example.com")

    out = StringIO()
    call_command("reset_user_entitlement", user.email, stdout=out)

    output = out.getvalue()
    assert "Before:" in output
    assert "After:" in output
    assert "is_ad_free=True" in output
    assert "is_ad_free=False" in output
    assert "cus_reset_target" in output


def test_unknown_email_raises_command_error():
    with pytest.raises(CommandError):
        call_command("reset_user_entitlement", "no-such-user@example.com", stdout=StringIO())


def test_soft_deleted_user_is_not_matched():
    user = _make_subscribed_user(email="softdeleted@example.com")
    user.soft_delete()

    with pytest.raises(CommandError):
        call_command("reset_user_entitlement", "softdeleted@example.com", stdout=StringIO())
