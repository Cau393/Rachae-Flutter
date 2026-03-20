import pytest
from unittest.mock import patch

def test_get_template_id_pt_br(settings):
    settings.BREVO_INVITATION_TEMPLATE_ID_PT_BR = 101
    from tasks.email_tasks import _get_template_id

    assert _get_template_id("INVITATION", "pt_BR") == 101


def test_get_template_id_falls_back_to_pt_br(settings):
    settings.BREVO_INVITATION_TEMPLATE_ID_PT_BR = 101
    from tasks.email_tasks import _get_template_id

    assert _get_template_id("INVITATION", "de_DE") == 101


def test_get_template_id_raises_for_unknown_event():
    from tasks.email_tasks import _get_template_id

    with pytest.raises(ValueError, match="No Brevo template configured"):
        _get_template_id("NONEXISTENT_EVENT", "pt_BR")


def test_get_template_id_raises_when_settings_key_zero(settings):
    settings.BREVO_INVITATION_TEMPLATE_ID_PT_BR = 0
    from tasks.email_tasks import _get_template_id

    with pytest.raises(ValueError, match="missing or zero"):
        _get_template_id("INVITATION", "pt_BR")


@pytest.mark.django_db
def test_send_invitation_email_sends_correct_params(
    mock_brevo, mock_template_id, settings
):
    from apps.users.models import User
    settings.FRONTEND_URL = "https://app.rachae.app"
    inviter = User.objects.create(
        supabase_uid="00000000-0000-0000-0000-000000000001",
        display_name="Ana Silva",
        email="ana@test.com",
        preferred_locale="pt_BR",
    )
    from tasks.email_tasks import send_invitation_email

    send_invitation_email(str(inviter.id), "joao@test.com", "tok123")

    mock_brevo.send_transac_email.assert_called_once()
    call_args = mock_brevo.send_transac_email.call_args[0][0]
    assert call_args.to == [{"email": "joao@test.com"}]
    assert "tok123" in call_args.params["join_url"]
    assert call_args.params["inviter_name"] == inviter.display_name


@pytest.mark.django_db
def test_send_invitation_email_retries_on_brevo_failure(mock_brevo, mock_template_id):
    mock_brevo.send_transac_email.side_effect = Exception("Brevo 500")
    from tasks.email_tasks import send_invitation_email

    with pytest.raises(Exception):
        send_invitation_email.apply(args=["invalid-uuid", "x@x.com", "tok"])


@pytest.mark.django_db
def test_send_expense_notification_sends_to_participant(
    mock_brevo, mock_template_id, expense_with_splits
):
    from apps.splits.models import Split as SplitModel
    import apps.expenses.models as expenses_models
    from tasks.email_tasks import send_expense_notification

    # Task imports Split from apps.expenses.models; alias it for this codebase layout.
    expenses_models.Split = SplitModel

    expense, participant = expense_with_splits
    send_expense_notification(str(participant.id), str(expense.id))

    mock_brevo.send_transac_email.assert_called_once()
    call_args = mock_brevo.send_transac_email.call_args[0][0]
    assert call_args.to[0]["email"] == participant.email
    assert "your_share" in call_args.params
    assert call_args.params["expense_desc"] == expense.description


@pytest.mark.django_db
def test_send_expense_notification_skips_creator(
    mock_brevo, mock_template_id, expense_with_splits
):
    from apps.splits.models import Split as SplitModel
    import apps.expenses.models as expenses_models
    from tasks.email_tasks import send_expense_notification

    expenses_models.Split = SplitModel

    expense, _participant = expense_with_splits
    send_expense_notification(str(expense.created_by.id), str(expense.id))

    mock_brevo.send_transac_email.assert_not_called()


@pytest.mark.django_db
def test_send_expense_notification_retries_on_failure(mock_brevo, mock_template_id):
    mock_brevo.send_transac_email.side_effect = Exception("timeout")
    from tasks.email_tasks import send_expense_notification

    with pytest.raises(Exception):
        send_expense_notification.apply(args=["invalid-uuid", "invalid-uuid"])


@pytest.mark.django_db
def test_send_settlement_confirmation_sends_to_both_parties(
    mock_brevo, mock_template_id, transaction_fixture
):
    from tasks.email_tasks import send_settlement_confirmation

    txn = transaction_fixture
    send_settlement_confirmation(str(txn.payer_id), str(txn.receiver_id), str(txn.id))

    assert mock_brevo.send_transac_email.call_count == 2
    recipients = {
        args[0][0].to[0]["email"]
        for args in mock_brevo.send_transac_email.call_args_list
    }
    assert txn.payer.email in recipients
    assert txn.receiver.email in recipients


@pytest.mark.django_db
def test_send_settlement_confirmation_uses_recorded_template_when_pending(
    mock_brevo, transaction_fixture
):
    from tasks.email_tasks import send_settlement_confirmation

    txn = transaction_fixture
    with patch("tasks.email_tasks._get_template_id") as mock_get_template:
        mock_get_template.return_value = 99
        send_settlement_confirmation(str(txn.payer_id), str(txn.receiver_id), str(txn.id))

    for call_args in mock_get_template.call_args_list:
        assert call_args[0][0] == "SETTLEMENT_RECORDED"


@pytest.mark.django_db
def test_send_settlement_confirmation_uses_confirmed_template_when_confirmed(
    mock_brevo, transaction_fixture
):
    from tasks.email_tasks import send_settlement_confirmation

    txn = transaction_fixture
    txn.is_confirmed = True
    txn.save(update_fields=["is_confirmed"])

    with patch("tasks.email_tasks._get_template_id") as mock_get_template:
        mock_get_template.return_value = 99
        send_settlement_confirmation(str(txn.payer_id), str(txn.receiver_id), str(txn.id))

    for call_args in mock_get_template.call_args_list:
        assert call_args[0][0] == "SETTLEMENT_CONFIRMED"


@pytest.mark.django_db
def test_send_settlement_confirmation_retries_on_failure(mock_brevo, mock_template_id):
    mock_brevo.send_transac_email.side_effect = Exception("Brevo error")
    from tasks.email_tasks import send_settlement_confirmation

    with pytest.raises(Exception):
        send_settlement_confirmation.apply(args=["a", "b", "invalid-uuid"])


@pytest.mark.django_db
def test_send_weekly_digest_sends_only_to_active_members(
    mock_brevo, mock_template_id, users_with_groups
):
    from tasks.email_tasks import send_weekly_digest

    active_users, inactive_user = users_with_groups
    with patch(
        "apps.ledger.services.LedgerService.net_balances_for_user", create=True
    ) as mock_ledger:
        mock_ledger.return_value = {
            "total_you_owe": "50.00",
            "total_owed_to_you": "100.00",
            "net": "50.00",
            "currency": "BRL",
            "by_group": [],
        }
        send_weekly_digest()

    assert mock_brevo.send_transac_email.call_count == len(active_users)
    sent_emails = {
        args[0][0].to[0]["email"]
        for args in mock_brevo.send_transac_email.call_args_list
    }
    assert inactive_user.email not in sent_emails


@pytest.mark.django_db
def test_send_weekly_digest_continues_after_per_user_failure(
    mock_brevo, mock_template_id, users_with_groups
):
    from tasks.email_tasks import send_weekly_digest

    active_users, _inactive_user = users_with_groups
    counter = {"calls": 0}

    def side_effect(*_args, **_kwargs):
        counter["calls"] += 1
        if counter["calls"] == 1:
            raise RuntimeError("Brevo rejected first user")

    mock_brevo.send_transac_email.side_effect = side_effect

    with patch(
        "apps.ledger.services.LedgerService.net_balances_for_user", create=True
    ) as mock_ledger:
        mock_ledger.return_value = {
            "total_you_owe": "0.00",
            "total_owed_to_you": "0.00",
            "net": "0.00",
            "currency": "BRL",
            "by_group": [],
        }
        send_weekly_digest()

    assert mock_brevo.send_transac_email.call_count == len(active_users)


@pytest.mark.django_db
def test_send_weekly_digest_uses_per_user_locale(mock_brevo, users_with_groups):
    from tasks.email_tasks import send_weekly_digest

    active_users, _inactive_user = users_with_groups
    locale_calls = []

    def capture_locale(event, locale):
        locale_calls.append(locale)
        return 42

    with patch("tasks.email_tasks._get_template_id", side_effect=capture_locale):
        with patch(
            "apps.ledger.services.LedgerService.net_balances_for_user", create=True
        ) as mock_ledger:
            mock_ledger.return_value = {
                "total_you_owe": "0.00",
                "total_owed_to_you": "0.00",
                "net": "0.00",
                "currency": "BRL",
                "by_group": [],
            }
            send_weekly_digest()

    expected_locales = [u.preferred_locale for u in active_users]
    assert sorted(locale_calls) == sorted(expected_locales)
