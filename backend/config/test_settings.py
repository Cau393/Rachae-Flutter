from config.settings import *  # noqa: F403,F401

# Do not load service account or call firebase_admin during pytest / manage.py test
FIREBASE_SKIP_INIT = True

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "test_db.sqlite3",  # noqa: F405
    },
}

CELERY_TASK_ALWAYS_EAGER = True
CELERY_TASK_EAGER_PROPAGATES = True
ALLOWED_HOSTS = ["testserver", "localhost", "127.0.0.1"]
FRONTEND_INVITE_URL = "http://localhost:3000/login"
CACHES = {
    "default": {
        "BACKEND": "django.core.cache.backends.locmem.LocMemCache",
        "LOCATION": "rachae-test-cache",
        "TIMEOUT": 300,
    }
}

MIDDLEWARE = [
    middleware
    for middleware in MIDDLEWARE  # noqa: F405
    if middleware != "whitenoise.middleware.WhiteNoiseMiddleware"
]
STORAGES["staticfiles"] = {  # noqa: F405
    "BACKEND": "django.core.files.storage.FileSystemStorage",
}
