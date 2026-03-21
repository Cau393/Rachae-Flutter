"""
ASGI shim: the real app lives in ``config.asgi``.

Use either ``uvicorn backend.asgi:application`` or ``uvicorn config.asgi:application``
from the ``backend/`` directory.
"""

from config.asgi import application

__all__ = ["application"]
