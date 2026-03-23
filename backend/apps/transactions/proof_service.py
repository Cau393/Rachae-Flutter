import uuid
from importlib import import_module

from django.conf import settings
from django.db import transaction as db_transaction
from django.utils import timezone
from rest_framework.exceptions import PermissionDenied, ValidationError

from apps.transactions.models import Transaction
from core.storage import generate_presigned_upload_url

PROOF_UPLOAD_EXPIRATION_SECONDS = 900


def _schedule_optional_task(module_path: str, task_name: str, *task_args) -> None:
    try:
        task_module = import_module(module_path)
    except ModuleNotFoundError:
        return

    task = getattr(task_module, task_name, None)
    if task is None:
        return

    db_transaction.on_commit(lambda task=task, task_args=task_args: task.delay(*task_args))


def _schedule_proof_confirmation(file_key: str) -> None:
    _schedule_optional_task(
        "tasks.s3_tasks",
        "s3_confirm_upload",
        file_key,
    )


class TransactionProofService:
    @staticmethod
    def _ensure_participant(txn: Transaction, user) -> None:
        if txn.payer_id != user.id and txn.receiver_id != user.id:
            raise PermissionDenied("You are not involved in this transaction.")

    @staticmethod
    def generate_upload_url(
        txn: Transaction,
        requesting_user,
        content_type: str = "image/jpeg",
    ) -> dict:
        TransactionProofService._ensure_participant(txn, requesting_user)

        timestamp = timezone.now().strftime("%Y%m%d%H%M%S")
        extension = TransactionProofService._extension_for_content_type(content_type)
        file_key = f"settlement-proofs/{txn.id}/{timestamp}-{uuid.uuid4()}.{extension}"
        upload_url = generate_presigned_upload_url(
            object_key=file_key,
            content_type=content_type,
            expires_in=PROOF_UPLOAD_EXPIRATION_SECONDS,
        )

        return {
            "upload_url": upload_url,
            "file_key": file_key,
            "expires_in": PROOF_UPLOAD_EXPIRATION_SECONDS,
        }

    @staticmethod
    def confirm_upload(txn: Transaction, file_key: str, actor) -> Transaction:
        TransactionProofService._ensure_participant(txn, actor)
        TransactionProofService._validate_proof_key(txn, file_key)
        if file_key in (txn.proof_urls or []):
            raise ValidationError({"detail": "This proof file has already been confirmed."})

        with db_transaction.atomic():
            txn.proof_urls = list(txn.proof_urls or []) + [file_key]
            txn.save(update_fields=["proof_urls"])
            _schedule_proof_confirmation(file_key)

        return txn

    @staticmethod
    def _validate_proof_key(txn: Transaction, file_key: str) -> None:
        expected_prefix = f"settlement-proofs/{txn.id}/"
        if not file_key.startswith(expected_prefix):
            raise ValidationError({"detail": "Proof file key does not belong to this transaction."})

    @staticmethod
    def _extension_for_content_type(content_type: str) -> str:
        normalized_content_type = (content_type or "application/octet-stream").lower()
        extensions = {
            "image/jpeg": "jpg",
            "image/jpg": "jpg",
            "image/png": "png",
            "application/pdf": "pdf",
        }
        return extensions.get(normalized_content_type, "bin")
