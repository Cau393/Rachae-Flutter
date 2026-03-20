from unittest.mock import MagicMock, patch

import pytest


def _make_client_error(code: str):
    from botocore.exceptions import ClientError

    return ClientError(
        error_response={"Error": {"Code": code, "Message": "test"}},
        operation_name="HeadObject",
    )


def test_delete_s3_object_calls_boto3_delete(mock_s3_client):
    from tasks.s3_tasks import delete_s3_object

    delete_s3_object("receipts/expense-uuid/photo.jpg")

    mock_s3_client.delete_object.assert_called_once_with(
        Bucket="rachae-receipts",
        Key="receipts/expense-uuid/photo.jpg",
    )


def test_delete_s3_object_is_idempotent(mock_s3_client):
    from tasks.s3_tasks import delete_s3_object

    mock_s3_client.delete_object.return_value = {}
    delete_s3_object("receipts/nonexistent/photo.jpg")


def test_delete_s3_object_retries_on_boto3_error(mock_s3_client):
    from tasks.s3_tasks import delete_s3_object

    mock_s3_client.delete_object.side_effect = Exception("Connection reset")

    with pytest.raises(Exception, match="Connection reset"):
        delete_s3_object.apply(args=["receipts/photo.jpg"])


def test_delete_s3_object_uses_settings_bucket(settings):
    from tasks.s3_tasks import delete_s3_object

    settings.AWS_S3_BUCKET = "my-custom-bucket"

    with patch("boto3.client") as mock_boto_client:
        mock_client = MagicMock()
        mock_boto_client.return_value = mock_client
        delete_s3_object("receipts/photo.jpg")

    assert mock_client.delete_object.call_count == 1
    assert mock_client.delete_object.call_args.kwargs["Bucket"] == "my-custom-bucket"


def test_s3_confirm_upload_does_nothing_when_object_exists(mock_s3_client):
    from tasks.s3_tasks import s3_confirm_upload

    mock_s3_client.head_object.return_value = {"ContentLength": 1024}
    s3_confirm_upload("receipts/expense-uuid/photo.jpg")

    mock_s3_client.head_object.assert_called_once()


def test_s3_confirm_upload_removes_stale_key_when_object_missing(
    mock_s3_client,
    expense_with_receipt_key,
):
    from tasks.s3_tasks import s3_confirm_upload

    expense, file_key = expense_with_receipt_key
    assert file_key in expense.receipt_urls

    mock_s3_client.head_object.side_effect = _make_client_error("404")
    s3_confirm_upload(file_key)

    expense.refresh_from_db()
    assert file_key not in expense.receipt_urls


def test_s3_confirm_upload_only_removes_matching_key(
    mock_s3_client,
    expense_with_multiple_receipt_keys,
):
    from tasks.s3_tasks import s3_confirm_upload

    expense, stale_key, good_key = expense_with_multiple_receipt_keys
    mock_s3_client.head_object.side_effect = _make_client_error("404")
    s3_confirm_upload(stale_key)

    expense.refresh_from_db()
    assert stale_key not in expense.receipt_urls
    assert good_key in expense.receipt_urls


def test_s3_confirm_upload_retries_on_unexpected_error(mock_s3_client):
    from tasks.s3_tasks import s3_confirm_upload

    mock_s3_client.head_object.side_effect = _make_client_error("403")

    with pytest.raises(Exception):
        s3_confirm_upload.apply(args=["receipts/photo.jpg"])


def test_cleanup_orphan_dispatches_delete_for_unreferenced_keys(
    mock_s3_client,
    expense_with_receipt_key,
):
    from tasks.s3_tasks import cleanup_orphan_s3_files

    _expense, known_key = expense_with_receipt_key
    orphan_key = "receipts/orphan-uuid/old-photo.jpg"

    mock_s3_client.list_objects_v2.return_value = {
        "Contents": [{"Key": known_key}, {"Key": orphan_key}],
        "IsTruncated": False,
    }

    with patch("tasks.s3_tasks.delete_s3_object") as mock_delete_task:
        mock_delete_task.delay = MagicMock()
        cleanup_orphan_s3_files()

    dispatched_keys = [c.args[0] for c in mock_delete_task.delay.call_args_list]
    assert orphan_key in dispatched_keys
    assert known_key not in dispatched_keys


def test_cleanup_orphan_handles_empty_bucket(mock_s3_client):
    from tasks.s3_tasks import cleanup_orphan_s3_files

    mock_s3_client.list_objects_v2.return_value = {"IsTruncated": False}
    cleanup_orphan_s3_files()


def test_cleanup_orphan_handles_paginated_s3_response(
    mock_s3_client,
    expense_with_receipt_key,
):
    from tasks.s3_tasks import cleanup_orphan_s3_files

    _expense, known_key = expense_with_receipt_key
    orphan_key = "receipts/orphan/photo.jpg"
    mock_s3_client.list_objects_v2.side_effect = [
        {
            "Contents": [{"Key": known_key}],
            "IsTruncated": True,
            "NextContinuationToken": "tok1",
        },
        {
            "Contents": [{"Key": orphan_key}],
            "IsTruncated": False,
        },
    ]

    with patch("tasks.s3_tasks.delete_s3_object") as mock_delete_task:
        mock_delete_task.delay = MagicMock()
        cleanup_orphan_s3_files()

    dispatched_keys = [c.args[0] for c in mock_delete_task.delay.call_args_list]
    assert orphan_key in dispatched_keys
    assert known_key not in dispatched_keys
