import logging

import pytest
from unittest.mock import MagicMock, patch

def test_get_template_id_pt_br(settings):
    settings.BREVO_EXPENSE_NOTIFICATION_TEMPLATE_ID_PT_BR = 101
    from tasks.email_tasks import _get_template_id

    assert _get_template_id("EXPENSE_NOTIFICATION", "pt_BR") == 101


def test_get_template_id_falls_back_to_pt_br(settings):
    settings.BREVO_EXPENSE_NOTIFICATION_TEMPLATE_ID_PT_BR = 101
    from tasks.email_tasks import _get_template_id

    assert _get_template_id("EXPENSE_NOTIFICATION", "de_DE") == 101


def test_get_template_id_raises_for_unknown_event():
    from tasks.email_tasks import _get_template_id

    with pytest.raises(ValueError, match="No Brevo template configured"):
        _get_template_id("NONEXISTENT_EVENT", "pt_BR")


def test_get_template_id_raises_when_settings_key_zero(settings):
    settings.BREVO_EXPENSE_NOTIFICATION_TEMPLATE_ID_PT_BR = 0
    from tasks.email_tasks import _get_template_id

    with pytest.raises(ValueError, match="missing or zero"):
        _get_template_id("EXPENSE_NOTIFICATION", "pt_BR")


def test_stringify_brevo_params_replaces_none_with_empty_string():
    from tasks.email_tasks import _stringify_brevo_params

    out = _stringify_brevo_params(
        {"a": None, "b": 10, "c": "x", "d": False}
    )
    assert out == {"a": "", "b": "10", "c": "x", "d": False}


def test_send_transac_template_logs_api_exception(caplog):
    from sib_api_v3_sdk.rest import ApiException

    from tasks.email_tasks import _send_transac_template

    mock_client = MagicMock()
    mock_client.send_transac_email.side_effect = ApiException(
        status=400, reason="Bad Request"
    )
    with caplog.at_level(logging.ERROR):
        with pytest.raises(ApiException):
            _send_transac_template(
                mock_client,
                to=[{"email": "a@b.com", "name": "A"}],
                template_id=1,
                params={"x": None},
            )
    assert "Brevo ApiException" in caplog.text
    assert "400" in caplog.text


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
    assert all(isinstance(v, str) for v in call_args.params.values())


@pytest.mark.django_db
def test_send_expense_notification_skips_when_brevo_api_key_missing(
    settings, expense_with_splits, monkeypatch
):
    from tasks.email_tasks import send_expense_notification

    settings.BREVO_API_KEY = ""
    mock_client = MagicMock()
    monkeypatch.setattr("tasks.email_tasks.get_brevo_client", lambda: mock_client)

    expense, participant = expense_with_splits
    send_expense_notification(str(participant.id), str(expense.id))

    mock_client.send_transac_email.assert_not_called()


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
