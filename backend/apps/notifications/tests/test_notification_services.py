import pytest


# ── NotificationService ───────────────────────────────────────────────────────


@pytest.mark.django_db
def test_create_notification_persists_to_db(notification_user, actor_user):
    from apps.notifications.services import NotificationService
    from apps.notifications.models import Notification

    notif = NotificationService.create(
        recipient=notification_user,
        notification_type="expense_created",
        title="Despesa adicionada",
        body="Ana adicionou R$100",
        data={"type": "expense", "id": "uuid-123"},
        actor=actor_user,
    )
    assert Notification.objects.filter(id=notif.id).exists()
    assert notif.is_read is False
    assert notif.recipient == notification_user
    assert notif.actor == actor_user


@pytest.mark.django_db
def test_create_notification_without_actor(notification_user):
    from apps.notifications.services import NotificationService

    notif = NotificationService.create(
        recipient=notification_user,
        notification_type="settlement_recorded",
        title="Pagamento registrado",
        body="Você recebeu R$50",
    )
    assert notif.actor is None


@pytest.mark.django_db
def test_unread_count_returns_correct_number(notification_user):
    from apps.notifications.services import NotificationService
    from apps.notifications.models import Notification

    Notification.objects.create(
        recipient=notification_user,
        notification_type="expense_created",
        title="T1",
        body="B1",
        is_read=False,
    )
    Notification.objects.create(
        recipient=notification_user,
        notification_type="expense_created",
        title="T2",
        body="B2",
        is_read=True,
    )
    Notification.objects.create(
        recipient=notification_user,
        notification_type="expense_created",
        title="T3",
        body="B3",
        is_read=False,
    )

    assert NotificationService.unread_count(notification_user) == 2


@pytest.mark.django_db
def test_mark_read_updates_single_notification(notification_user):
    from apps.notifications.services import NotificationService
    from apps.notifications.models import Notification

    notif = Notification.objects.create(
        recipient=notification_user,
        notification_type="expense_created",
        title="T",
        body="B",
        is_read=False,
    )
    NotificationService.mark_read(notif)
    notif.refresh_from_db()
    assert notif.is_read is True


@pytest.mark.django_db
def test_mark_all_read_returns_count(notification_user):
    from apps.notifications.services import NotificationService
    from apps.notifications.models import Notification

    for i in range(3):
        Notification.objects.create(
            recipient=notification_user,
            notification_type="expense_created",
            title=f"T{i}",
            body="B",
            is_read=False,
        )

    count = NotificationService.mark_all_read(notification_user)
    assert count == 3
    assert NotificationService.unread_count(notification_user) == 0


# ── PreferenceService ─────────────────────────────────────────────────────────


@pytest.mark.django_db
def test_get_or_create_returns_defaults(notification_user):
    from apps.notifications.services import PreferenceService

    pref = PreferenceService.get_or_create(notification_user)
    assert pref.push_expense_created is True
    assert pref.email_expense_created is True


@pytest.mark.django_db
def test_get_or_create_is_idempotent(notification_user):
    from apps.notifications.services import PreferenceService

    p1 = PreferenceService.get_or_create(notification_user)
    p2 = PreferenceService.get_or_create(notification_user)
    assert p1.id == p2.id


@pytest.mark.django_db
def test_update_preferences_persists_changes(notification_user):
    from apps.notifications.services import PreferenceService

    pref = PreferenceService.get_or_create(notification_user)
    PreferenceService.update(
        pref,
        {"email_settlement_recorded": False, "push_expense_created": False},
    )
    pref.refresh_from_db()
    assert pref.email_settlement_recorded is False
    assert pref.push_expense_created is False
    assert pref.push_settlement_recorded is True


# ── DeviceTokenService ────────────────────────────────────────────────────────


@pytest.mark.django_db
def test_register_token_creates_record(notification_user):
    from apps.notifications.services import DeviceTokenService
    from apps.notifications.models import DeviceToken

    DeviceTokenService.register(notification_user, token="tok_123", device_type="ios")
    assert DeviceToken.objects.filter(user=notification_user, token="tok_123").exists()


@pytest.mark.django_db
def test_register_token_does_not_duplicate(notification_user):
    from apps.notifications.services import DeviceTokenService
    from apps.notifications.models import DeviceToken

    DeviceTokenService.register(notification_user, token="tok_dup", device_type="ios")
    DeviceTokenService.register(notification_user, token="tok_dup", device_type="android")
    assert DeviceToken.objects.filter(token="tok_dup").count() == 1


@pytest.mark.django_db
def test_remove_token_deletes_record(notification_user):
    from apps.notifications.services import DeviceTokenService
    from apps.notifications.models import DeviceToken

    DeviceToken.objects.create(user=notification_user, token="tok_del", device_type="ios")
    DeviceTokenService.remove(notification_user, token="tok_del")
    assert not DeviceToken.objects.filter(token="tok_del").exists()


@pytest.mark.django_db
def test_remove_nonexistent_token_does_not_raise(notification_user):
    from apps.notifications.services import DeviceTokenService

    DeviceTokenService.remove(notification_user, token="nonexistent_token")
