import pytest


@pytest.mark.django_db
def test_send_push_creates_in_app_notification(
    notification_user_with_token,
    mock_firebase,
):
    from tasks.notification_tasks import send_push_notification

    send_push_notification(
        user_id=str(notification_user_with_token.id),
        title="Despesa adicionada",
        body="Ana adicionou R$100",
        data={"type": "expense", "id": "uuid-123"},
        notification_type="expense_created",
    )
    from apps.notifications.models import Notification

    assert Notification.objects.filter(
        recipient=notification_user_with_token,
        notification_type="expense_created",
    ).exists()


@pytest.mark.django_db
def test_send_push_calls_firebase_with_all_tokens(
    notification_user_with_token,
    mock_firebase,
):
    from tasks.notification_tasks import send_push_notification

    send_push_notification(
        user_id=str(notification_user_with_token.id),
        title="Test",
        body="Body",
        data={},
        notification_type="expense_created",
    )
    mock_firebase.send_each_for_multicast.assert_called_once()
    msg = mock_firebase.send_each_for_multicast.call_args[0][0]
    assert len(msg.tokens) > 0


@pytest.mark.django_db
def test_send_push_skips_when_no_device_tokens(
    notification_user_no_token,
    mock_firebase,
):
    from tasks.notification_tasks import send_push_notification

    send_push_notification(
        user_id=str(notification_user_no_token.id),
        title="Test",
        body="Body",
        data={},
        notification_type="expense_created",
    )
    mock_firebase.send_each_for_multicast.assert_not_called()
    from apps.notifications.models import Notification

    assert Notification.objects.filter(recipient=notification_user_no_token).exists()


@pytest.mark.django_db
def test_send_push_respects_push_preference_disabled(
    notification_user_with_token,
    mock_firebase,
):
    from apps.notifications.services import PreferenceService
    from tasks.notification_tasks import send_push_notification

    pref = PreferenceService.get_or_create(notification_user_with_token)
    PreferenceService.update(pref, {"push_expense_created": False})
    send_push_notification(
        user_id=str(notification_user_with_token.id),
        title="Test",
        body="Body",
        data={},
        notification_type="expense_created",
    )
    mock_firebase.send_each_for_multicast.assert_not_called()
    from apps.notifications.models import Notification

    assert Notification.objects.filter(recipient=notification_user_with_token).exists()


@pytest.mark.django_db
def test_send_push_removes_invalid_tokens(
    notification_user_with_token,
    mock_firebase_with_invalid_token,
):
    from apps.notifications.models import DeviceToken
    from tasks.notification_tasks import send_push_notification

    send_push_notification(
        user_id=str(notification_user_with_token.id),
        title="Test",
        body="Body",
        data={},
        notification_type="expense_created",
    )
    assert DeviceToken.objects.filter(user=notification_user_with_token).count() == 0


@pytest.mark.django_db
def test_send_push_retries_on_firebase_error(
    notification_user_with_token,
    mock_firebase,
):
    from tasks.notification_tasks import send_push_notification

    mock_firebase.send_each_for_multicast.side_effect = Exception("Firebase unavailable")
    with pytest.raises(Exception, match="Firebase unavailable"):
        send_push_notification.apply(
            args=[
                str(notification_user_with_token.id),
                "Test",
                "Body",
                {},
                "expense_created",
            ]
        )


@pytest.mark.django_db
def test_send_push_does_nothing_for_nonexistent_user():
    from tasks.notification_tasks import send_push_notification

    send_push_notification.apply(
        args=[
            "00000000-0000-0000-0000-000000000000",
            "Test",
            "Body",
            {},
            "expense_created",
        ]
    )
