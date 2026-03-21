import os

from celery import Celery
from celery.schedules import crontab

os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")

app = Celery("rachae")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks(
    [
        "tasks.email_tasks",
        "tasks.ledger_tasks",
        "tasks.s3_tasks",
        "tasks.currency_tasks",
        "tasks.notification_tasks",
        "tasks.stripe_tasks",
    ]
)

app.conf.update(
    task_acks_late=True,
    task_reject_on_worker_lost=True,
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    timezone="UTC",
    enable_utc=True,
    task_soft_time_limit=300,
    task_time_limit=600,
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=100,
)

app.conf.beat_schedule = {
    "refresh-exchange-rates-daily": {
        "task": "tasks.currency_tasks.refresh_exchange_rates",
        "schedule": crontab(hour=9, minute=0),
        "options": {"expires": 3600},
    },
    "send-weekly-digest-monday": {
        "task": "tasks.email_tasks.send_weekly_digest",
        "schedule": crontab(hour=11, minute=0, day_of_week=1),
        "options": {"expires": 3600},
    },
    "cleanup-orphan-s3-files-weekly": {
        "task": "tasks.s3_tasks.cleanup_orphan_s3_files",
        "schedule": crontab(hour=3, minute=0, day_of_week=0),
        "options": {"expires": 7200},
    },
    "run-debt-simplification-daily": {
        "task": "tasks.ledger_tasks.run_debt_simplification_all_groups",
        "schedule": crontab(hour=10, minute=0),
        "options": {"expires": 3600},
    },
}
