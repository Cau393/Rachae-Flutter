import pytest


# ── GET /api/v1/notifications/ ────────────────────────────────────────────────


@pytest.mark.django_db
def test_list_returns_user_notifications_only(auth_client, user_notifications, other_user_notification):
    response = auth_client.get("/api/v1/notifications/")
    assert response.status_code == 200
    ids = [n["id"] for n in response.json()["data"]]
    assert str(other_user_notification.id) not in ids
    assert all(str(n.id) in ids for n in user_notifications)


@pytest.mark.django_db
def test_list_includes_x_unread_count_header(auth_client, user_notifications):
    response = auth_client.get("/api/v1/notifications/")
    assert "X-Unread-Count" in response
    unread_count = int(response["X-Unread-Count"])
    expected = sum(1 for n in user_notifications if not n.is_read)
    assert unread_count == expected


@pytest.mark.django_db
def test_list_orders_newest_first(auth_client, user_notifications):
    response = auth_client.get("/api/v1/notifications/")
    timestamps = [n["created_at"] for n in response.json()["data"]]
    assert timestamps == sorted(timestamps, reverse=True)


@pytest.mark.django_db
def test_list_response_shape(auth_client, user_notifications):
    response = auth_client.get("/api/v1/notifications/")
    item = response.json()["data"][0]
    assert {"id", "notification_type", "title", "body", "data", "is_read", "created_at"}.issubset(
        item.keys()
    )


@pytest.mark.django_db
def test_list_requires_auth(api_client):
    response = api_client.get("/api/v1/notifications/")
    assert response.status_code in (401, 403)


# ── PATCH /api/v1/notifications/{id}/read/ ───────────────────────────────────────────


@pytest.mark.django_db
def test_mark_single_read(auth_client, user_notifications):
    unread = next(n for n in user_notifications if not n.is_read)
    response = auth_client.patch(f"/api/v1/notifications/{unread.id}/read/")
    assert response.status_code == 200
    unread.refresh_from_db()
    assert unread.is_read is True


@pytest.mark.django_db
def test_mark_read_is_idempotent(auth_client, user_notifications):
    already_read = next(n for n in user_notifications if n.is_read)
    response = auth_client.patch(f"/api/v1/notifications/{already_read.id}/read/")
    assert response.status_code == 200


@pytest.mark.django_db
def test_mark_read_cannot_access_other_users_notification(auth_client, other_user_notification):
    response = auth_client.patch(f"/api/v1/notifications/{other_user_notification.id}/read/")
    assert response.status_code == 404


# ── PATCH /api/v1/notifications/read-all/ ────────────────────────────────────────────


@pytest.mark.django_db
def test_read_all_marks_all_as_read(auth_client, user_notifications):
    response = auth_client.patch("/api/v1/notifications/read-all/")
    assert response.status_code == 200
    for n in user_notifications:
        n.refresh_from_db()
        assert n.is_read is True


@pytest.mark.django_db
def test_read_all_does_not_affect_other_users(auth_client, user_notifications, other_user_notification):
    auth_client.patch("/api/v1/notifications/read-all/")
    other_user_notification.refresh_from_db()
    assert other_user_notification.is_read is False


@pytest.mark.django_db
def test_read_all_returns_count(auth_client, user_notifications):
    response = auth_client.patch("/api/v1/notifications/read-all/")
    assert "marked_read" in response.json()["data"]
    assert response.json()["data"]["marked_read"] >= 0


# ── GET/PATCH /api/v1/notifications/preferences/ ──────────────────────────────────────


@pytest.mark.django_db
def test_get_preferences_returns_all_fields(auth_client):
    response = auth_client.get("/api/v1/notifications/preferences/")
    assert response.status_code == 200
    data = response.json()["data"]
    assert {
        "push_expense_created",
        "push_settlement_recorded",
        "push_group_invitation",
        "email_expense_created",
        "email_settlement_recorded",
        "email_weekly_digest",
    } == set(data.keys())


@pytest.mark.django_db
def test_get_preferences_creates_defaults_on_first_access(auth_client):
    response = auth_client.get("/api/v1/notifications/preferences/")
    data = response.json()["data"]
    assert all(v is True for v in data.values())


@pytest.mark.django_db
def test_patch_preferences_updates_specific_fields(auth_client):
    auth_client.patch(
        "/api/v1/notifications/preferences/",
        data={"email_weekly_digest": False},
        content_type="application/json",
    )
    response = auth_client.get("/api/v1/notifications/preferences/")
    data = response.json()["data"]
    assert data["email_weekly_digest"] is False
    assert data["push_expense_created"] is True


@pytest.mark.django_db
def test_patch_preferences_invalid_field_returns_400(auth_client):
    response = auth_client.patch(
        "/api/v1/notifications/preferences/",
        data={"nonexistent_preference": True},
        content_type="application/json",
    )
    assert response.status_code == 400


# ── POST/DELETE /api/v1/notifications/device-token/ ─────────────────────────────────────────


@pytest.mark.django_db
def test_register_device_token_creates_record(auth_client, auth_user):
    response = auth_client.post(
        "/api/v1/notifications/device-token/",
        data={"token": "fcm_token_abc123", "device_type": "ios"},
        content_type="application/json",
    )
    assert response.status_code == 201
    from apps.notifications.models import DeviceToken

    assert DeviceToken.objects.filter(user=auth_user, token="fcm_token_abc123").exists()


@pytest.mark.django_db
def test_register_device_token_upserts_on_duplicate(auth_client, auth_user):
    for _ in range(2):
        auth_client.post(
            "/api/v1/notifications/device-token/",
            data={"token": "fcm_dup_token", "device_type": "android"},
            content_type="application/json",
        )
    from apps.notifications.models import DeviceToken

    assert DeviceToken.objects.filter(token="fcm_dup_token").count() == 1


@pytest.mark.django_db
def test_delete_device_token_removes_record(auth_client, auth_user):
    from apps.notifications.models import DeviceToken

    DeviceToken.objects.create(user=auth_user, token="token_to_delete", device_type="ios")
    response = auth_client.delete(
        "/api/v1/notifications/device-token/",
        data={"token": "token_to_delete"},
        content_type="application/json",
    )
    assert response.status_code == 204
    assert not DeviceToken.objects.filter(token="token_to_delete").exists()
