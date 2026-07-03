import logging

from rest_framework.views import exception_handler as drf_exception_handler

logger = logging.getLogger(__name__)


def logging_exception_handler(exc, context):
    """Wrap DRF's default handler to surface 4xx errors in production logs.

    `django.request` is configured at ERROR level (see settings.LOGGING) so
    5xx tracebacks reach Railway, but DRF resolves ValidationError/
    PermissionDenied/etc. into a normal Response before Django's logging
    middleware ever sees an exception — client errors were silently dropped.
    """
    response = drf_exception_handler(exc, context)
    if response is not None and 400 <= response.status_code < 500:
        request = context.get("request")
        path = getattr(request, "path", "unknown")
        logger.warning("%s %s -> %s", path, response.status_code, response.data)
    return response
