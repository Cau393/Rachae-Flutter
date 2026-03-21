"""
One-time Firebase Admin SDK initialization for FCM.

Call :func:`ensure_firebase_initialized` from ``AppConfig.ready`` so Django and
Celery workers share the same default app before ``notification_tasks`` sends pushes.
"""

from __future__ import annotations

import logging
import sys
from pathlib import Path

from django.conf import settings
from django.core.exceptions import ImproperlyConfigured

logger = logging.getLogger(__name__)

_done = False


def ensure_firebase_initialized() -> None:
    """Idempotent: loads service account JSON and calls ``firebase_admin.initialize_app`` once."""
    global _done
    if _done:
        return

    if getattr(settings, "FIREBASE_SKIP_INIT", False):
        _done = True
        logger.debug("Firebase Admin init skipped (FIREBASE_SKIP_INIT).")
        return

    raw_path = getattr(settings, "FIREBASE_CREDENTIALS_PATH", None)
    if not raw_path:
        logger.debug(
            "Firebase Admin not configured (FIREBASE_CREDENTIALS_JSON unset); "
            "FCM will fail until credentials are set."
        )
        _done = True
        return

    path = Path(raw_path)
    if not path.is_file():
        msg = f"Firebase credentials file not found: {path}"
        logger.error(msg)
        raise ImproperlyConfigured(msg)

    try:
        import firebase_admin
        from firebase_admin import credentials
    except ImportError as exc:
        logger.warning(
            "firebase_admin not installed (%s). Use the same interpreter as your venv "
            "(e.g. python -m uvicorn …) or run: %s -m pip install firebase-admin. "
            "To skip FCM init locally, set FIREBASE_SKIP_INIT=1 in .env.",
            exc,
            sys.executable,
        )
        _done = True
        return

    try:
        firebase_admin.get_app()
    except ValueError:
        try:
            firebase_admin.initialize_app(credentials.Certificate(str(path)))
        except Exception:
            logger.exception("Firebase Admin initialize_app failed")
            raise
        logger.info("Firebase Admin initialized for FCM (default app).")
    else:
        logger.debug("Firebase Admin default app already initialized.")

    _done = True
