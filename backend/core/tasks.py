from celery import shared_task


@shared_task(
    bind=True,
    autoretry_for=(Exception,),
    retry_backoff=True,
    retry_jitter=True,
    max_retries=3,
)
def heartbeat_task(self):
    # The task is idempotent because it only reports static health metadata.
    return {
        "task": "heartbeat",
        "status": "ok",
        "attempt": self.request.retries + 1,
    }
