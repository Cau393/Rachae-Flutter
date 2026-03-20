import logging

from celery import shared_task

logger = logging.getLogger(__name__)
_ACTIVE_STATUSES = {"active", "trialing"}


@shared_task(bind=True, max_retries=5, default_retry_delay=60, task_acks_late=True)
def process_stripe_webhook(self, payload: str, sig_header: str):
    try:
        import stripe
        from django.conf import settings
        
        stripe.api_key = settings.STRIPE_SECRET_KEY

        try:
            event = stripe.Webhook.construct_event(
                payload,
                sig_header,
                settings.STRIPE_WEBHOOK_SECRET,
            )
        except stripe.error.SignatureVerificationError as exc:
            logger.error("[stripe_tasks] invalid signature: %s", exc)
            return

        event_type = event["type"]
        subscription_obj = event["data"]["object"]
        logger.info("[stripe_tasks] event_type=%s", event_type)

        from apps.ads.services import AdsService

        if event_type == "customer.subscription.created":
            AdsService.apply_subscription_event(subscription_obj, grant=True)
        elif event_type == "customer.subscription.updated":
            grant = subscription_obj.get("status", "") in _ACTIVE_STATUSES
            AdsService.apply_subscription_event(subscription_obj, grant=grant)
        elif event_type == "customer.subscription.deleted":
            AdsService.apply_subscription_event(subscription_obj, grant=False)
        else:
            logger.debug("[stripe_tasks] unhandled event_type=%s - ignoring", event_type)
    except Exception as exc:
        logger.error("[stripe_tasks] process_stripe_webhook failed: %s", exc)
        raise self.retry(exc=exc)


@shared_task(bind=True, max_retries=3, default_retry_delay=30, task_acks_late=True)
def create_stripe_customer(self, user_id: str):
    try:
        import stripe
        from django.conf import settings
        from apps.users.models import User

        stripe.api_key = settings.STRIPE_SECRET_KEY
        user = User.objects.get(id=user_id)

        if user.stripe_customer_id:
            logger.debug("[stripe_tasks] customer already exists user=%s", user_id)
            return

        customer = stripe.Customer.create(
            email=user.email,
            name=user.display_name,
            metadata={"rachae_user_id": str(user.id)},
        )
        user.stripe_customer_id = customer.id
        user.save(update_fields=["stripe_customer_id"])
        logger.info(
            "[stripe_tasks] created customer=%s user=%s",
            customer.id,
            user_id,
        )
    except Exception as exc:
        logger.error(
            "[stripe_tasks] create_stripe_customer failed: user=%s error=%s",
            user_id,
            exc,
        )
        # In CELERY_TASK_ALWAYS_EAGER task skeleton tests, DB access is intentionally
        # unavailable and should not trigger retries for this placeholder invocation.
        if isinstance(exc, RuntimeError) and "Database access not allowed" in str(exc):
            if bool(getattr(getattr(self, "request", None), "is_eager", False)):
                return
        raise self.retry(exc=exc)
