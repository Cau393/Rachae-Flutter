import os
import sys
import uuid
from decimal import Decimal
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import django
import pytest
from django.apps import apps

# Ensure backend is importable when pytest is run from repo root.
BACKEND_DIR = Path(__file__).resolve().parents[2]
if str(BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(BACKEND_DIR))

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.test_settings")
if not apps.ready:
    django.setup()


@pytest.fixture(autouse=True)
def celery_eager(settings):
    settings.CELERY_TASK_ALWAYS_EAGER = True
    settings.CELERY_TASK_EAGER_PROPAGATES = True


@pytest.fixture
def mock_brevo(monkeypatch):
    mock_client = MagicMock()
    monkeypatch.setattr("tasks.email_tasks.get_brevo_client", lambda: mock_client)
    return mock_client


@pytest.fixture
def mock_template_id(monkeypatch):
    monkeypatch.setattr("tasks.email_tasks._get_template_id", lambda event, locale: 42)


@pytest.fixture
def expense_with_splits(db):
    from apps.expenses.models import Expense
    from apps.groups.models import Group, GroupMember, GroupRole
    from apps.splits.models import Split
    from apps.users.models import User

    creator = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="creator@test.com",
        display_name="Creator",
        preferred_locale="pt_BR",
    )
    participant = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="participant@test.com",
        display_name="Participant",
        preferred_locale="pt_BR",
    )

    group = Group.objects.create(name="Test Group", currency="BRL", created_by=creator)
    GroupMember.objects.create(group=group, user=creator, role=GroupRole.ADMIN)
    GroupMember.objects.create(group=group, user=participant, role=GroupRole.MEMBER)

    expense = Expense.objects.create(
        group=group,
        paid_by=creator,
        amount=Decimal("100.00"),
        currency="BRL",
        exchange_rate_to_group_currency=Decimal("1.000000"),
        amount_in_group_currency=Decimal("100.00"),
        description="Jantar",
        category="comida",
        created_by=creator,
    )
    Split.objects.create(expense=expense, user=creator, amount_owed=Decimal("50.00"))
    Split.objects.create(expense=expense, user=participant, amount_owed=Decimal("50.00"))

    return expense, participant


@pytest.fixture
def transaction_fixture(db):
    from apps.transactions.models import Transaction
    from apps.users.models import User

    payer = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="payer@test.com",
        display_name="Payer",
        preferred_locale="pt_BR",
    )
    receiver = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="receiver@test.com",
        display_name="Receiver",
        preferred_locale="pt_BR",
    )

    return Transaction.objects.create(
        payer=payer,
        receiver=receiver,
        amount=Decimal("125.00"),
        currency="BRL",
        is_confirmed=False,
    )


@pytest.fixture
def users_with_groups(db):
    from apps.groups.models import Group, GroupMember, GroupRole
    from apps.users.models import User

    u1 = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="u1@test.com",
        display_name="U1",
        preferred_locale="pt_BR",
    )
    u2 = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="u2@test.com",
        display_name="U2",
        preferred_locale="en_US",
    )
    inactive = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="inactive@test.com",
        display_name="Inactive",
        preferred_locale="pt_BR",
    )

    group = Group.objects.create(name="Group", currency="BRL", created_by=u1)
    GroupMember.objects.create(group=group, user=u1, role=GroupRole.ADMIN)
    GroupMember.objects.create(group=group, user=u2, role=GroupRole.MEMBER)

    return [u1, u2], inactive


@pytest.fixture
def django_cache():
    from django.core.cache import cache

    cache.clear()
    yield cache
    cache.clear()


@pytest.fixture
def group_with_expenses(db, django_user_model):
    from apps.expenses.models import Expense
    from apps.groups.models import Group, GroupMember, GroupRole
    from apps.splits.models import Split
    from apps.users.models import User

    u0 = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="u0@test.com",
        display_name="U0",
        preferred_locale="pt_BR",
    )
    u1 = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="u1@test.com",
        display_name="U1",
        preferred_locale="pt_BR",
    )

    group = Group.objects.create(
        name="Group With Expenses",
        currency="BRL",
        created_by=u0,
        simplify_debts=True,
    )
    GroupMember.objects.create(group=group, user=u0, role=GroupRole.ADMIN)
    GroupMember.objects.create(group=group, user=u1, role=GroupRole.MEMBER)

    expense = Expense.objects.create(
        group=group,
        paid_by=u0,
        created_by=u0,
        amount=Decimal("100.00"),
        currency="BRL",
        exchange_rate_to_group_currency=Decimal("1.000000"),
        amount_in_group_currency=Decimal("100.00"),
        description="Shared expense",
        category="geral",
    )
    Split.objects.create(expense=expense, user=u0, amount_owed=Decimal("50.00"))
    Split.objects.create(expense=expense, user=u1, amount_owed=Decimal("50.00"))

    return group, [u0, u1]


@pytest.fixture
def group_simplify_off(db, django_user_model):
    from apps.groups.models import Group
    from apps.users.models import User

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="simplify-off@test.com",
        display_name="Simplify Off",
        preferred_locale="pt_BR",
    )
    return Group.objects.create(
        name="Simplify Off",
        currency="BRL",
        created_by=user,
        simplify_debts=False,
    )


@pytest.fixture
def deleted_group(db, django_user_model):
    from apps.groups.models import Group
    from apps.users.models import User

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="deleted-group@test.com",
        display_name="Deleted Group User",
        preferred_locale="pt_BR",
    )
    return Group.objects.create(
        name="Deleted Group",
        currency="BRL",
        created_by=user,
        simplify_debts=True,
        is_deleted=True,
    )


@pytest.fixture
def multiple_groups(db, django_user_model):
    from apps.groups.models import Group, GroupMember, GroupRole
    from apps.users.models import User

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="multiple-groups@test.com",
        display_name="Multiple Groups",
        preferred_locale="pt_BR",
    )

    ag1 = Group.objects.create(
        name="Active Group 1",
        currency="BRL",
        created_by=user,
        simplify_debts=True,
        is_deleted=False,
    )
    ag2 = Group.objects.create(
        name="Active Group 2",
        currency="BRL",
        created_by=user,
        simplify_debts=True,
        is_deleted=False,
    )
    dg = Group.objects.create(
        name="Deleted Group",
        currency="BRL",
        created_by=user,
        simplify_debts=True,
        is_deleted=True,
    )
    sg = Group.objects.create(
        name="Simplification Disabled",
        currency="BRL",
        created_by=user,
        simplify_debts=False,
        is_deleted=False,
    )

    GroupMember.objects.create(group=ag1, user=user, role=GroupRole.ADMIN)
    GroupMember.objects.create(group=ag2, user=user, role=GroupRole.ADMIN)
    GroupMember.objects.create(group=dg, user=user, role=GroupRole.ADMIN)
    GroupMember.objects.create(group=sg, user=user, role=GroupRole.ADMIN)

    return [ag1, ag2], dg, sg


@pytest.fixture
def mock_s3_client(settings):
    settings.AWS_S3_BUCKET = "rachae-receipts"
    settings.AWS_S3_REGION = "us-east-1"
    settings.AWS_ACCESS_KEY_ID = "test-key-id"
    settings.AWS_SECRET_ACCESS_KEY = "test-secret"

    mock_client = MagicMock()
    mock_client.delete_object.return_value = {}
    mock_client.head_object.return_value = {"ContentLength": 512}
    mock_client.list_objects_v2.return_value = {"IsTruncated": False}

    with patch("boto3.client", return_value=mock_client):
        yield mock_client


@pytest.fixture
def expense_with_receipt_key(db, django_user_model):
    from apps.expenses.models import Expense
    from apps.groups.models import Group
    from apps.users.models import User

    receipt_key = "receipts/test-expense-uuid/photo.jpg"
    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="receipt-single@test.com",
        display_name="Receipt Single",
        preferred_locale="pt_BR",
    )
    group = Group.objects.create(
        name="Receipt Group",
        currency="BRL",
        created_by=user,
    )

    expense = Expense.objects.create(
        group=group,
        paid_by=user,
        created_by=user,
        amount=Decimal("10.00"),
        currency="BRL",
        exchange_rate_to_group_currency=Decimal("1.000000"),
        amount_in_group_currency=Decimal("10.00"),
        description="Expense with receipt",
        category="geral",
        receipt_urls=[receipt_key],
    )
    return expense, receipt_key


@pytest.fixture
def expense_with_multiple_receipt_keys(db, django_user_model):
    from apps.expenses.models import Expense
    from apps.groups.models import Group
    from apps.users.models import User

    stale_key = "receipts/stale-uuid/stale.jpg"
    good_key = "receipts/good-uuid/good.jpg"
    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="receipt-multiple@test.com",
        display_name="Receipt Multiple",
        preferred_locale="pt_BR",
    )
    group = Group.objects.create(
        name="Receipt Multi Group",
        currency="BRL",
        created_by=user,
    )

    expense = Expense.objects.create(
        group=group,
        paid_by=user,
        created_by=user,
        amount=Decimal("20.00"),
        currency="BRL",
        exchange_rate_to_group_currency=Decimal("1.000000"),
        amount_in_group_currency=Decimal("20.00"),
        description="Expense with multiple receipts",
        category="geral",
        receipt_urls=[stale_key, good_key],
    )
    return expense, stale_key, good_key


@pytest.fixture
def mock_exchange_api():
    patchers = []

    def _factory(rates: dict):
        mock_response = MagicMock()
        mock_response.raise_for_status = MagicMock()
        mock_response.json.return_value = {"conversion_rates": rates}
        patcher = patch("requests.get", return_value=mock_response)
        patchers.append(patcher)
        patcher.start()
        return mock_response

    yield _factory

    while patchers:
        patchers.pop().stop()


@pytest.fixture
def mock_s3_client(monkeypatch):
    mock_client = MagicMock()
    monkeypatch.setattr("tasks.s3_tasks.get_s3_client", lambda: mock_client)
    return mock_client


@pytest.fixture
def expense_with_receipt_key(db):
    from apps.expenses.models import Expense
    from apps.groups.models import Group, GroupMember, GroupRole
    from apps.users.models import User

    creator = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="s3_creator@test.com",
        display_name="S3 Creator",
        preferred_locale="pt_BR",
    )
    group = Group.objects.create(name="S3 Group", currency="BRL", created_by=creator)
    GroupMember.objects.create(group=group, user=creator, role=GroupRole.ADMIN)

    file_key = "receipts/expense-uuid/photo.jpg"
    expense = Expense.objects.create(
        group=group,
        paid_by=creator,
        amount=Decimal("10.00"),
        currency="BRL",
        exchange_rate_to_group_currency=Decimal("1.000000"),
        amount_in_group_currency=Decimal("10.00"),
        description="Receipt test",
        category="comida",
        created_by=creator,
        receipt_urls=[file_key],
    )
    return expense, file_key


@pytest.fixture
def expense_with_multiple_receipt_keys(db):
    from apps.expenses.models import Expense
    from apps.groups.models import Group, GroupMember, GroupRole
    from apps.users.models import User

    creator = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="s3_creator_multi@test.com",
        display_name="S3 Creator Multi",
        preferred_locale="pt_BR",
    )
    group = Group.objects.create(name="S3 Group Multi", currency="BRL", created_by=creator)
    GroupMember.objects.create(group=group, user=creator, role=GroupRole.ADMIN)

    stale_key = "receipts/stale-uuid/old-photo.jpg"
    good_key = "receipts/good-uuid/new-photo.jpg"
    expense = Expense.objects.create(
        group=group,
        paid_by=creator,
        amount=Decimal("20.00"),
        currency="BRL",
        exchange_rate_to_group_currency=Decimal("1.000000"),
        amount_in_group_currency=Decimal("20.00"),
        description="Multiple receipts test",
        category="geral",
        created_by=creator,
        receipt_urls=[stale_key, good_key],
    )
    return expense, stale_key, good_key


@pytest.fixture
def mock_stripe(settings):
    import stripe as stripe_lib

    settings.STRIPE_SECRET_KEY = "sk_test_fake"
    settings.STRIPE_WEBHOOK_SECRET = "whsec_test_fake"
    settings.STRIPE_PRICE_MONTHLY = "price_monthly_test"
    settings.STRIPE_PRICE_YEARLY = "price_yearly_test"

    mock_s = MagicMock()
    mock_s.error = stripe_lib.error
    mock_s.Webhook.construct_event.return_value = {}
    mock_s.Customer.create.return_value = MagicMock(id="cus_mock123")

    with patch.dict(sys.modules, {"stripe": mock_s}):
        yield mock_s


@pytest.fixture
def stripe_user(db, django_user_model):
    from apps.users.models import User

    del django_user_model

    return User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="stripe-user@test.com",
        display_name="Stripe User",
        preferred_locale="pt_BR",
        stripe_customer_id="cus_existing123",
        is_ad_free=False,
    )


@pytest.fixture
def stripe_user_subscribed(db, django_user_model):
    from datetime import timedelta

    from apps.users.models import User
    from django.utils import timezone

    del django_user_model

    model_field_names = {field.name for field in User._meta.fields}
    optional_values = {}
    if "subscription_status" in model_field_names:
        optional_values["subscription_status"] = "active"
    if "plan_type" in model_field_names:
        optional_values["plan_type"] = "monthly"
    if "plan_expires_at" in model_field_names:
        optional_values["plan_expires_at"] = timezone.now() + timedelta(days=30)

    return User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="stripe-user-subscribed@test.com",
        display_name="Stripe User Subscribed",
        preferred_locale="pt_BR",
        stripe_customer_id="cus_subbed456",
        is_ad_free=True,
        **optional_values,
    )


@pytest.fixture
def user_without_stripe(db, django_user_model):
    from apps.users.models import User

    del django_user_model

    return User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="user-without-stripe@test.com",
        display_name="User Without Stripe",
        preferred_locale="pt_BR",
        stripe_customer_id=None,
    )


# --- Notification task tests (mirrors apps/notifications/tests/conftest.py) ---


@pytest.fixture
def notification_user_with_token(db):
    from apps.notifications.models import DeviceToken
    from apps.users.models import User

    user = User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="pushuser@rachae.app",
        display_name="Push User",
        preferred_locale="pt_BR",
    )
    DeviceToken.objects.create(user=user, token="valid_fcm_token_001", device_type="ios")
    return user


@pytest.fixture
def notification_user_no_token(db):
    from apps.users.models import User

    return User.objects.create(
        supabase_uid=uuid.uuid4(),
        email="notoken@rachae.app",
        display_name="No Token",
        preferred_locale="pt_BR",
    )


@pytest.fixture
def mock_firebase():
    mock_messaging = MagicMock()
    mock_messaging.MulticastMessage.side_effect = lambda **kwargs: SimpleNamespace(
        **kwargs
    )
    mock_messaging.Notification.side_effect = lambda **kwargs: SimpleNamespace(**kwargs)
    mock_response = MagicMock()
    mock_response.responses = [MagicMock(success=True, exception=None)]
    mock_response.success_count = 1
    mock_response.failure_count = 0
    mock_messaging.send_each_for_multicast.return_value = mock_response
    with patch("tasks.notification_tasks.messaging", mock_messaging):
        yield mock_messaging


@pytest.fixture
def mock_firebase_with_invalid_token(db, notification_user_with_token):
    # Real firebase UnregisteredError.code is read-only; use a mock with settable code.
    failed_exc = MagicMock()
    failed_exc.code = "registration-token-not-registered"
    failed_resp = MagicMock(success=False, exception=failed_exc)
    mock_response = MagicMock(responses=[failed_resp], success_count=0, failure_count=1)
    mock_messaging = MagicMock()
    mock_messaging.MulticastMessage.side_effect = lambda **kwargs: SimpleNamespace(
        **kwargs
    )
    mock_messaging.Notification.side_effect = lambda **kwargs: SimpleNamespace(**kwargs)
    mock_messaging.send_each_for_multicast.return_value = mock_response
    with patch("tasks.notification_tasks.messaging", mock_messaging):
        yield mock_messaging
