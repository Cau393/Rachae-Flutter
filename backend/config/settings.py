import sys
import os
import importlib.util
from pathlib import Path

import dj_database_url
import environ

BASE_DIR = Path(__file__).resolve().parent.parent
ROOT_DIR = BASE_DIR.parent
HAS_WHITENOISE = importlib.util.find_spec("whitenoise") is not None
TESTING = "test" in sys.argv or "pytest" in sys.modules

env = environ.Env(
    DJANGO_DEBUG=(bool, False),
    DJANGO_ALLOWED_HOSTS=(str, "localhost,127.0.0.1"),
    CORS_ALLOWED_ORIGINS=(str, "http://localhost:3000,http://127.0.0.1:3000,http://localhost:61523,http://127.0.0.1:61523,http://192.168.1.114:61523"),
    CORS_ALLOWED_ORIGIN_REGEXES=(str, r"^https?://192\.168\.\d+\.\d+(:\d+)?$"),
)
environ.Env.read_env(ROOT_DIR / ".env")

SECRET_KEY = env("DJANGO_SECRET_KEY")
DEBUG = env("DJANGO_DEBUG")
ALLOWED_HOSTS = [host.strip() for host in env("DJANGO_ALLOWED_HOSTS").split(",") if host.strip()]
CORS_ALLOWED_ORIGINS = [origin.strip() for origin in env("CORS_ALLOWED_ORIGINS").split(",") if origin.strip()]
# The 192.168.x.x LAN regex is a dev-only convenience (testing from a phone
# on the same Wi-Fi as `flutter run`). Never let it reach production — gate
# it behind DEBUG so a misconfigured/missing env override can't ship it.
CORS_ALLOWED_ORIGIN_REGEXES = (
    [pattern.strip() for pattern in env("CORS_ALLOWED_ORIGIN_REGEXES").split(",") if pattern.strip()]
    if DEBUG
    else []
)
CORS_ALLOW_HEADERS = [
    "accept",
    "accept-encoding",
    "authorization",
    "content-type",
    "dnt",
    "origin",
    "user-agent",
    "x-csrftoken",
    "x-requested-with",
]

INSTALLED_APPS = [
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "corsheaders",
    "rest_framework",
    "django_celery_beat",
    "core",
    "apps.groups",
    "apps.expenses",
    "apps.splits",
    "apps.transactions",
    "apps.ledger",
    "apps.currencies",
    "apps.users",
    "apps.ads",
    "apps.notifications",
]

AUTH_USER_MODEL = "users.User"

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "corsheaders.middleware.CorsMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
]
if HAS_WHITENOISE:
    MIDDLEWARE.insert(1, "whitenoise.middleware.WhiteNoiseMiddleware")

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"
ASGI_APPLICATION = "config.asgi.application"

if TESTING:
    DATABASES = {
        'default': {
            'ENGINE': 'django.db.backends.sqlite3',
            'NAME': ':memory:',
        }
    }
else:
    DATABASES = {
        "default": dj_database_url.parse(
            env("DATABASE_URL"),
                conn_max_age=600,
                conn_health_checks=True,
            ),
        }
    
if DATABASES["default"]["ENGINE"] == "django.db.backends.postgresql":
    DATABASES["default"].setdefault("OPTIONS", {})
    DATABASES["default"]["OPTIONS"].setdefault("connect_timeout", 5)


def _normalize_redis_url(url: str) -> str:
    """Normalize Redis URLs for redis-py 7+ and Celery.

    - Maps legacy ``ssl_cert_reqs=CERT_*`` query flags to ``none``/``optional``/``required``.
    - Upgrades ``redis://`` → ``rediss://`` when SSL params are present (Upstash).
    """
    for old, new in (
        ("ssl_cert_reqs=CERT_NONE", "ssl_cert_reqs=none"),
        ("ssl_cert_reqs=CERT_OPTIONAL", "ssl_cert_reqs=optional"),
        ("ssl_cert_reqs=CERT_REQUIRED", "ssl_cert_reqs=required"),
    ):
        if old in url:
            url = url.replace(old, new)
    needs_tls = (
        "ssl_cert_reqs=" in url
        or ".upstash.io" in url
    )
    if needs_tls and url.startswith("redis://"):
        url = "rediss://" + url[len("redis://") :]
    return url


# Redis + Celery
REDIS_URL = _normalize_redis_url(os.environ.get("REDIS_URL", "redis://localhost:6379/0"))
CELERY_BROKER_URL = REDIS_URL
CELERY_RESULT_BACKEND = REDIS_URL
CELERY_BROKER_CONNECTION_RETRY_ON_STARTUP = True
_default_cache = {
    "BACKEND": "django.core.cache.backends.redis.RedisCache",
    "LOCATION": REDIS_URL,
    "KEY_PREFIX": "rachae",
    "TIMEOUT": 300,
    # NOTE: Django's built-in RedisCache forwards OPTIONS to redis-py, which
    # does NOT accept django-redis's IGNORE_EXCEPTIONS — passing it raised
    # TypeError on every cache access (only surfaced once throttling made the
    # cache a per-request hot path). Restoring "degrade a Redis blip to a DB
    # read" needs the django-redis backend; tracked as a follow-up.
    "OPTIONS": {},
}
if REDIS_URL.startswith("rediss://"):
    _default_cache["OPTIONS"]["ssl_cert_reqs"] = "none"
CACHES = {"default": _default_cache}
if TESTING:
    CACHES = {
        "default": {
            "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
            "LOCATION": "rachae-test-cache",
            "TIMEOUT": 300,
        }
    }

# External services — Brevo transactional template IDs (numeric), not marketing campaign IDs.
# Example test IDs from Brevo UI: expense=4, settlement recorded=5, confirmed=6.
BREVO_API_KEY = os.environ.get('BREVO_API_KEY', '')
BREVO_EXPENSE_NOTIFICATION_TEMPLATE_ID_PT_BR = int(os.environ.get('BREVO_EXPENSE_NOTIFICATION_TEMPLATE_ID_PT_BR', 0))
BREVO_SETTLEMENT_RECORDED_TEMPLATE_ID_PT_BR = int(os.environ.get('BREVO_SETTLEMENT_RECORDED_TEMPLATE_ID_PT_BR', 0))
BREVO_SETTLEMENT_CONFIRMED_TEMPLATE_ID_PT_BR = int(os.environ.get('BREVO_SETTLEMENT_CONFIRMED_TEMPLATE_ID_PT_BR', 0))
FRONTEND_URL = os.environ.get('FRONTEND_URL', 'https://app.rachae.app')
AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID', '')
AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY', '')
AWS_S3_REGION = os.environ.get('AWS_S3_REGION', 'sa-east-1')
AWS_S3_BUCKET = os.environ.get('AWS_S3_BUCKET', 'rachae-receipts')
CLOUDFRONT_DOMAIN = os.environ.get('CLOUDFRONT_DOMAIN', '')
STRIPE_SECRET_KEY = os.environ.get('STRIPE_SECRET_KEY', '')
# Use the Dashboard endpoint signing secret in deployed envs. For local `stripe listen`,
# paste the CLI's "Webhook signing secret" (whsec_...) — it differs from Dashboard.
STRIPE_WEBHOOK_SECRET = os.environ.get('STRIPE_WEBHOOK_SECRET', '')
STRIPE_PRICE_MONTHLY = os.environ.get('STRIPE_PRICE_MONTHLY', '')
STRIPE_PRICE_YEARLY = os.environ.get('STRIPE_PRICE_YEARLY', '')
# RevenueCat dashboard → Webhooks → Authorization (optional). If set, POSTs must send the same token in Authorization (Bearer prefix or raw secret).
REVENUECAT_WEBHOOK_SECRET = os.environ.get('REVENUECAT_WEBHOOK_SECRET', '')
# RevenueCat dashboard → API keys → Secret API key. Used server-side by POST /ads/sync/
# to pull a user's current entitlement directly instead of waiting on a webhook.
REVENUECAT_API_KEY = os.environ.get('REVENUECAT_API_KEY', '')
SUPABASE_URL = os.environ.get('SUPABASE_URL', '')
EXCHANGE_RATE_API_KEY = os.environ.get('EXCHANGE_RATE_API_KEY', '')
EXCHANGE_RATE_API_URL = 'https://v6.exchangerate-api.com/v6'
SENTRY_DSN = os.environ.get('SENTRY_DSN', '')

# Firebase Cloud Messaging (service account JSON path). Relative paths resolve from repo ROOT_DIR.
_firebase_cred_raw = env("FIREBASE_CREDENTIALS_JSON", default="").strip()
if _firebase_cred_raw:
    _firebase_cred_path = Path(_firebase_cred_raw)
    FIREBASE_CREDENTIALS_PATH = str(
        _firebase_cred_path.resolve()
        if _firebase_cred_path.is_absolute()
        else (ROOT_DIR / _firebase_cred_path).resolve()
    )
else:
    FIREBASE_CREDENTIALS_PATH = None

# Skip Firebase Admin init (FCM) — tests override via config.test_settings.
# Set FIREBASE_SKIP_INIT=1 in .env if credentials exist but firebase-admin is not installed in this interpreter.
FIREBASE_SKIP_INIT = env.bool("FIREBASE_SKIP_INIT", default=False)

AUTH_PASSWORD_VALIDATORS = []

LANGUAGE_CODE = "en-us"
TIME_ZONE = "America/Sao_Paulo"
USE_I18N = True
USE_TZ = True

STATIC_URL = "static/"
STATIC_ROOT = BASE_DIR / "staticfiles"
STORAGES = {
    "default": {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    },
    "staticfiles": {
        "BACKEND": (
            "whitenoise.storage.CompressedManifestStaticFilesStorage"
            if HAS_WHITENOISE
            else "django.core.files.storage.FileSystemStorage"
        ),
    },
}

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"

REST_FRAMEWORK = {
    "DEFAULT_AUTHENTICATION_CLASSES": [
        "core.authentication.SupabaseJWTAuthentication",
    ],
    "DEFAULT_PERMISSION_CLASSES": [
        "rest_framework.permissions.IsAuthenticated",
    ],
    "DEFAULT_PAGINATION_CLASS": "rest_framework.pagination.PageNumberPagination",
    "PAGE_SIZE": 20,
    "EXCEPTION_HANDLER": "core.exceptions.logging_exception_handler",
    # NOTE: throttling counters live in CACHES["default"] — RedisCache in
    # prod/staging, LocMemCache under TESTING. LocMem is per-process and
    # would under-throttle behind multiple gunicorn workers, but Railway
    # prod already runs on the shared Redis cache above, so this is fine.
    "DEFAULT_THROTTLE_CLASSES": [
        "rest_framework.throttling.UserRateThrottle",
        "rest_framework.throttling.AnonRateThrottle",
    ],
    "DEFAULT_THROTTLE_RATES": {
        "user": "1000/day",
        "anon": "60/hour",
        "search": "30/min",
    },
}

SUPABASE_ISSUER = f"{SUPABASE_URL}/auth/v1"
# Supabase GoTrue sets `aud: "authenticated"` on every access token issued to
# a logged-in user. Pinning it here rejects tokens minted for any other
# audience (defense-in-depth on top of signature + issuer checks).
SUPABASE_JWT_AUDIENCE = os.environ.get("SUPABASE_JWT_AUDIENCE", "authenticated")

# Emit unhandled 500 tracebacks to stderr (→ Railway logs). Django's default
# routes django.request errors to mail_admins only, so with DEBUG=False and no
# email backend they are silently dropped and production 500s look invisible.
LOGGING = {
    "version": 1,
    "disable_existing_loggers": False,
    "formatters": {
        "verbose": {"format": "[{levelname}] {asctime} {name}: {message}", "style": "{"},
    },
    "handlers": {
        "console": {"class": "logging.StreamHandler", "formatter": "verbose"},
    },
    "root": {"handlers": ["console"], "level": "INFO"},
    "loggers": {
        "django.request": {"handlers": ["console"], "level": "ERROR", "propagate": False},
    },
}

# TLS for Redis (Upstash / secure Redis).
# redis-py 7+ validates ssl_cert_reqs only for strings "none" | "optional" | "required"
# (see redis.connection.SSLConnection); ssl.CERT_NONE can surface as invalid "CERT_NONE".
if REDIS_URL.startswith("rediss://"):
    CELERY_BROKER_USE_SSL = {
        "ssl_cert_reqs": "none",
    }
    CELERY_REDIS_BACKEND_USE_SSL = {
        "ssl_cert_reqs": "none",
    }
else:
    CELERY_BROKER_USE_SSL = None
    CELERY_REDIS_BACKEND_USE_SSL = None

# Task execution behaviour
CELERY_TASK_TRACK_STARTED = True
CELERY_TASK_TIME_LIMIT = 300
CELERY_TASK_SOFT_TIME_LIMIT = 240

# Worker reliability
CELERY_TASK_ACKS_LATE = True
CELERY_WORKER_PREFETCH_MULTIPLIER = 1
CELERY_WORKER_MAX_TASKS_PER_CHILD = 1000

# Serialization
CELERY_ACCEPT_CONTENT = ["json"]
CELERY_TASK_SERIALIZER = "json"
CELERY_RESULT_SERIALIZER = "json"

# Time settings
CELERY_ENABLE_UTC = True
CELERY_TIMEZONE = "UTC"

# Development helpers
CELERY_TASK_ALWAYS_EAGER = env.bool("CELERY_TASK_ALWAYS_EAGER", default=False)
CELERY_TASK_EAGER_PROPAGATES = env.bool("CELERY_TASK_EAGER_PROPAGATES", default=False)

EMAIL_FROM = env("EMAIL_FROM", default="")
EMAIL_FROM_NAME = env("EMAIL_FROM_NAME", default="Rachae")
FRONTEND_INVITE_URL = env("FRONTEND_INVITE_URL", default="http://localhost:3000/login")

# Production transport/security headers. The app terminates TLS at Railway's
# proxy, so SECURE_PROXY_SSL_HEADER must come first — without it,
# request.is_secure() is always False and SECURE_SSL_REDIRECT would loop.
if not DEBUG:
    SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")
    SECURE_SSL_REDIRECT = True
    # Railway probes the container directly over HTTP (no X-Forwarded-Proto),
    # so the health check must be exempt or SSL redirect 301s it and the
    # deploy's healthcheck fails.
    SECURE_REDIRECT_EXEMPT = [r"^api/v1/health/$"]
    SECURE_HSTS_SECONDS = 31536000
    SECURE_HSTS_INCLUDE_SUBDOMAINS = True
    SECURE_HSTS_PRELOAD = True
    SECURE_CONTENT_TYPE_NOSNIFF = True
    SESSION_COOKIE_SECURE = True
    CSRF_COOKIE_SECURE = True
    X_FRAME_OPTIONS = "DENY"

if SENTRY_DSN:
    import sentry_sdk
    from sentry_sdk.integrations.django import DjangoIntegration
    from sentry_sdk.integrations.celery import CeleryIntegration
    from sentry_sdk.integrations.redis import RedisIntegration

    sentry_sdk.init(
        dsn=SENTRY_DSN,
        integrations=[DjangoIntegration(), CeleryIntegration(), RedisIntegration()],
        traces_sample_rate=0.1,
        send_default_pii=False,
    )
