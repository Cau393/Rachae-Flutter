import logging

from celery import shared_task

logger = logging.getLogger(__name__)


def get_s3_client():
    import boto3
    from django.conf import settings

    return boto3.client(
        "s3",
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
        region_name=settings.AWS_S3_REGION,
    )


@shared_task(bind=True, max_retries=3, default_retry_delay=60, task_acks_late=True)
def delete_s3_object(self, file_key: str):
    try:
        from django.conf import settings

        s3 = get_s3_client()
        s3.delete_object(Bucket=settings.AWS_S3_BUCKET, Key=file_key)
        logger.info("[s3_tasks] delete_s3_object: deleted key=%s", file_key)
    except Exception as exc:
        logger.error("[s3_tasks] delete_s3_object failed: key=%s error=%s", file_key, exc)
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=30, task_acks_late=True)
def s3_confirm_upload(self, file_key: str):
    try:
        from botocore.exceptions import ClientError
        from django.conf import settings

        s3 = get_s3_client()

        try:
            s3.head_object(Bucket=settings.AWS_S3_BUCKET, Key=file_key)
            logger.info("[s3_tasks] s3_confirm_upload: confirmed key=%s", file_key)
        except ClientError as ce:
            error_code = ce.response["Error"]["Code"]
            if error_code == "404":
                logger.warning("[s3_tasks] s3_confirm_upload: missing, cleaning up key=%s", file_key)
                from apps.expenses.models import Expense
                from django.db.utils import NotSupportedError

                try:
                    expenses = list(Expense.objects.filter(receipt_urls__contains=[file_key]))
                except NotSupportedError:
                    expenses = [
                        expense
                        for expense in Expense.objects.all()
                        if file_key in (expense.receipt_urls or [])
                    ]

                for expense in expenses:
                    expense.receipt_urls = [k for k in expense.receipt_urls if k != file_key]
                    expense.save(update_fields=["receipt_urls"])
            else:
                raise
    except Exception as exc:
        logger.error("[s3_tasks] s3_confirm_upload failed: key=%s error=%s", file_key, exc)
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=2, default_retry_delay=300, task_acks_late=True)
def cleanup_orphan_s3_files(self):
    try:
        from django.conf import settings
        from apps.expenses.models import Expense

        s3 = get_s3_client()

        s3_keys: set[str] = set()
        kwargs: dict = {"Bucket": settings.AWS_S3_BUCKET, "Prefix": "receipts/"}

        while True:
            response = s3.list_objects_v2(**kwargs)
            for obj in response.get("Contents", []):
                s3_keys.add(obj["Key"])
            if not response.get("IsTruncated"):
                break
            kwargs["ContinuationToken"] = response["NextContinuationToken"]

        if not s3_keys:
            logger.info("[s3_tasks] cleanup_orphan_s3_files: bucket empty, nothing to do")
            return

        referenced_keys: set[str] = set()
        for urls in Expense.objects.filter(is_deleted=False).values_list("receipt_urls", flat=True):
            if urls:
                referenced_keys.update(urls)

        orphans = s3_keys - referenced_keys
        for key in orphans:
            delete_s3_object.delay(key)

        logger.info(
            "[s3_tasks] cleanup_orphan_s3_files: s3=%d referenced=%d orphans=%d",
            len(s3_keys), len(referenced_keys), len(orphans)
        )
    except Exception as exc:
        logger.error("[s3_tasks] cleanup_orphan_s3_files failed: %s", exc)
        raise self.retry(exc=exc)
