"""
Shared fixtures for notifications tests.

Requires ``apps.notifications`` in INSTALLED_APPS with ``Notification`` and
``DeviceToken`` models (and migrations applied). View tests hit
``/api/v1/notifications/`` and will 404 until ``urls.py`` is wired in
``config/urls.py``.
"""

import time
import uuid
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

import pytest
from rest_framework.test import APIClient


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def notification_user(db, django_user_model):
    return django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="notif@rachae.app",
        display_name="Notif User",
        preferred_locale="pt_BR",
    )


@pytest.fixture
def actor_user(db, django_user_model):
    return django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="actor@rachae.app",
        display_name="Actor",
        preferred_locale="pt_BR",
    )


@pytest.fixture
def auth_user(db, django_user_model):
    return django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="auth@rachae.app",
        display_name="Auth",
        preferred_locale="pt_BR",
    )


@pytest.fixture
def auth_client(auth_user):
    client = APIClient()
    client.force_authenticate(user=auth_user)
    return client


@pytest.fixture
def other_user(db, django_user_model):
    return django_user_model.objects.create(
        supabase_uid=uuid.uuid4(),
        email="other@rachae.app",
        display_name="Other",
        preferred_locale="pt_BR",
    )


@pytest.fixture
def user_notifications(db, auth_user):
    """Three notifications for auth_user: 2 unread, 1 read; distinct created_at."""
    from apps.notifications.models import Notification

    notifs = []
    for i, is_read in enumerate([False, False, True]):
        n = Notification.objects.create(
            recipient=auth_user,
            notification_type="expense_created",
            title=f"Notification {i}",
            body=f"Body {i}",
            is_read=is_read,
        )
        notifs.append(n)
        time.sleep(0.01)
    return notifs


@pytest.fixture
def other_user_notification(db, other_user):
    from apps.notifications.models import Notification

    return Notification.objects.create(
        recipient=other_user,
        notification_type="expense_created",
        title="Other notification",
        body="Not yours",
        is_read=False,
    )


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
    mock_messaging = MagicMock()
    mock_messaging.MulticastMessage.side_effect = lambda **kwargs: SimpleNamespace(
        **kwargs
    )
    mock_messaging.Notification.side_effect = lambda **kwargs: SimpleNamespace(**kwargs)

    failed_response = MagicMock()
    failed_response.success = False
    failed_exc = MagicMock()
    failed_exc.code = "registration-token-not-registered"
    failed_response.exception = failed_exc

    mock_response = MagicMock()
    mock_response.responses = [failed_response]
    mock_response.success_count = 0
    mock_response.failure_count = 1
    mock_messaging.send_each_for_multicast.return_value = mock_response

    with patch("tasks.notification_tasks.messaging", mock_messaging):
        yield mock_messaging
