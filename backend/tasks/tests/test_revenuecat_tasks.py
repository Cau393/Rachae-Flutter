import uuid
from datetime import timedelta

import pytest
from django.utils import timezone

from tasks.revenuecat_tasks import process_rc_webhook

pytestmark = pytest.mark.django_db


def test_process_rc_webhook_initial_purchase_grants(django_user_model):
    user = django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="rc_grant@example.com",
        display_name="RC Grant",
    )
    exp_ms = int((timezone.now().timestamp() + 86400) * 1000)
    process_rc_webhook.apply(
        args=[
            {
                "event": {
                    "type": "INITIAL_PURCHASE",
                    "app_user_id": str(user.id),
                    "product_id": "com.cau393.rachae.adfree.monthly",
                    "expiration_at_ms": exp_ms,
                },
            },
        ],
        throw=True,
    )
    user.refresh_from_db()
    assert user.is_ad_free is True
    assert user.subscription_status == "active"
    assert user.plan_type == "monthly"
    assert user.plan_expires_at is not None


def test_process_rc_webhook_initial_purchase_lifetime(django_user_model):
    user = django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="rc_lifetime@example.com",
        display_name="RC Lifetime",
    )
    exp_ms = int((timezone.now().timestamp() + 86400 * 365) * 1000)
    process_rc_webhook.apply(
        args=[
            {
                "event": {
                    "type": "INITIAL_PURCHASE",
                    "app_user_id": str(user.id),
                    "product_id": "com.app.rachae_pro.lifetime",
                    "expiration_at_ms": exp_ms,
                },
            },
        ],
        throw=True,
    )
    user.refresh_from_db()
    assert user.is_ad_free is True
    assert user.subscription_status == "active"
    assert user.plan_type == "lifetime"


def test_process_rc_webhook_renewal_yearly(django_user_model):
    user = django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="rc_year@example.com",
        display_name="RC Year",
    )
    exp_ms = int((timezone.now().timestamp() + 86400 * 365) * 1000)
    process_rc_webhook.apply(
        args=[
            {
                "event": {
                    "type": "RENEWAL",
                    "app_user_id": str(user.id),
                    "product_id": "com.cau393.rachae.adfree.yearly",
                    "expiration_at_ms": exp_ms,
                },
            },
        ],
        throw=True,
    )
    user.refresh_from_db()
    assert user.is_ad_free is True
    assert user.plan_type == "yearly"


def test_process_rc_webhook_expiration_revokes(django_user_model):
    user = django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="rc_exp@example.com",
        display_name="RC Exp",
        is_ad_free=True,
        subscription_status="active",
        plan_type="monthly",
        plan_expires_at=timezone.now() + timedelta(days=5),
    )
    process_rc_webhook.apply(
        args=[
            {
                "event": {
                    "type": "EXPIRATION",
                    "app_user_id": str(user.id),
                },
            },
        ],
        throw=True,
    )
    user.refresh_from_db()
    assert user.is_ad_free is False
    assert user.subscription_status == "expired"
    assert user.plan_type is None
    assert user.plan_expires_at is None


def test_process_rc_webhook_cancellation_revokes(django_user_model):
    user = django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="rc_cancel@example.com",
        display_name="RC Cancel",
        is_ad_free=True,
        subscription_status="active",
    )
    process_rc_webhook.apply(
        args=[
            {
                "event": {
                    "type": "CANCELLATION",
                    "app_user_id": str(user.id),
                },
            },
        ],
        throw=True,
    )
    user.refresh_from_db()
    assert user.is_ad_free is False
    assert user.subscription_status == "canceled"


def test_process_rc_webhook_unknown_user_is_no_op():
    process_rc_webhook.apply(
        args=[
            {
                "event": {
                    "type": "INITIAL_PURCHASE",
                    "app_user_id": str(uuid.uuid4()),
                },
            },
        ],
        throw=True,
    )


def test_process_rc_webhook_missing_app_user_id():
    process_rc_webhook.apply(
        args=[{"event": {"type": "INITIAL_PURCHASE"}}],
        throw=True,
    )


def test_process_rc_webhook_idempotent_duplicate_grant(django_user_model):
    user = django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="rc_idem@example.com",
        display_name="RC Idem",
    )
    exp_ms = int((timezone.now().timestamp() + 86400) * 1000)
    body = {
        "event": {
            "type": "INITIAL_PURCHASE",
            "app_user_id": str(user.id),
            "product_id": "com.cau393.rachae.adfree.monthly",
            "expiration_at_ms": exp_ms,
        },
    }
    process_rc_webhook.apply(args=[body], throw=True)
    process_rc_webhook.apply(args=[body], throw=True)
    user.refresh_from_db()
    assert user.is_ad_free is True


def test_process_rc_webhook_product_change_updates_plan(django_user_model):
    user = django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="rc_pc@example.com",
        display_name="RC PC",
        is_ad_free=True,
        subscription_status="active",
        plan_type="monthly",
    )
    exp_ms = int((timezone.now().timestamp() + 86400 * 365) * 1000)
    process_rc_webhook.apply(
        args=[
            {
                "event": {
                    "type": "PRODUCT_CHANGE",
                    "app_user_id": str(user.id),
                    "product_id": "com.cau393.rachae.adfree.yearly",
                    "expiration_at_ms": exp_ms,
                },
            },
        ],
        throw=True,
    )
    user.refresh_from_db()
    assert user.is_ad_free is True
    assert user.subscription_status == "active"
    assert user.plan_type == "yearly"
    assert user.plan_expires_at is not None
