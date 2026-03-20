import boto3
from django.conf import settings


def get_s3_client():
    return boto3.client(
        "s3",
        region_name=settings.AWS_S3_REGION,
        aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
        aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    )


def generate_presigned_upload_url(
    object_key: str,
    content_type: str,
    expires_in: int = 300,
) -> str:
    return get_s3_client().generate_presigned_url(
        "put_object",
        Params={
            "Bucket": settings.AWS_S3_BUCKET,
            "Key": object_key,
            "ContentType": content_type,
        },
        ExpiresIn=expires_in,
    )


def resolve_cloudfront_url(object_key: str | None) -> str | None:
    if not object_key:
        return None

    if object_key.startswith(("http://", "https://")):
        return object_key

    cloudfront_domain = getattr(settings, "CLOUDFRONT_DOMAIN", "") or getattr(
        settings,
        "AWS_CLOUDFRONT_DOMAIN",
        "",
    )
    if not cloudfront_domain:
        return object_key

    normalized_domain = cloudfront_domain.rstrip("/")
    normalized_key = object_key.lstrip("/")
    return f"https://{normalized_domain}/{normalized_key}"
