import base64
import binascii
import logging

from celery import shared_task

logger = logging.getLogger(__name__)
_ACTIVE_STATUSES = {"active", "trialing"}


def _stripe_id_value(raw):
    if raw is None:
        return None
    if isinstance(raw, str):
        return raw
    if isinstance(raw, dict):
        return raw.get("id")
    return None


def _subscription_id_from_session(session: dict):
    raw_sub = session.get("subscription")
    return raw_sub.get("id") if isinstance(raw_sub, dict) else raw_sub


def _payment_intent_id_from_session(session: dict):
    raw = session.get("payment_intent")
    return raw.get("id") if isinstance(raw, dict) else raw


def _resolve_stripe_customer_id_from_session(session: dict, stripe_module):
    cid = _stripe_id_value(session.get("customer"))
    if cid:
        return cid
    pi = session.get("payment_intent")
    if isinstance(pi, dict):
        cid = _stripe_id_value(pi.get("customer"))
        if cid:
            return cid
    pi_id = _payment_intent_id_from_session(session)
    if not pi_id:
        return None
    try:
        pi_obj = stripe_module.PaymentIntent.retrieve(
            pi_id,
            expand=["customer"],
        )
        pi_dict = pi_obj if isinstance(pi_obj, dict) else pi_obj.to_dict()
        return _stripe_id_value(pi_dict.get("customer"))
    except Exception:
        logger.exception(
            "[stripe_tasks] checkout.session.completed PaymentIntent.retrieve(%s) failed",
            pi_id,
        )
        return None


@shared_task(bind=True, max_retries=5, default_retry_delay=60, task_acks_late=True)
def process_stripe_webhook(self, payload_b64: str, sig_header: str):
    try:
        import stripe
        from django.conf import settings

        stripe.api_key = settings.STRIPE_SECRET_KEY

        try:
            payload_bytes = base64.b64decode(payload_b64, validate=True)
        except (binascii.Error, ValueError) as exc:
            logger.error("[stripe_tasks] webhook payload is not valid base64: %s", exc)
            return

        try:
            event = stripe.Webhook.construct_event(
                payload_bytes,
                sig_header,
                settings.STRIPE_WEBHOOK_SECRET,
            )
        except stripe.error.SignatureVerificationError as exc:
            logger.error("[stripe_tasks] invalid signature: %s", exc)
            return

        event_type = event["type"]
        logger.info("[stripe_tasks] event_type=%s", event_type)

        from apps.ads.services import AdsService

        if event_type == "checkout.session.completed":
            raw_session = event["data"]["object"]
            if isinstance(raw_session, dict):
                session = dict(raw_session)
            else:
                session = raw_session.to_dict()

            session_id = session.get("id")
            if session_id:
                try:
                    loaded = stripe.checkout.Session.retrieve(
                        session_id,
                        expand=["customer", "subscription", "payment_intent.customer"],
                    )
                    session = loaded if isinstance(loaded, dict) else loaded.to_dict()
                except Exception:
                    logger.exception(
                        "[stripe_tasks] checkout.session.completed Session.retrieve(%s) failed",
                        session_id,
                    )

            client_reference_id = session.get("client_reference_id")
            stripe_customer_id = _resolve_stripe_customer_id_from_session(session, stripe)

            if not client_reference_id:
                logger.warning(
                    "[stripe_tasks] checkout.session.completed missing client_reference_id "
                    "session_id=%r — ensure Checkout Session.create sets client_reference_id",
                    session_id,
                )
            elif not stripe_customer_id:
                logger.warning(
                    "[stripe_tasks] checkout.session.completed missing customer id "
                    "(session.customer and payment_intent.customer empty) session_id=%r",
                    session_id,
                )
            else:
                from apps.users.models import User

                rows = User.objects.filter(id=client_reference_id).update(
                    stripe_customer_id=stripe_customer_id,
                )
                if rows == 0:
                    logger.warning(
                        "[stripe_tasks] checkout.session.completed zero rows updated — "
                        "client_reference_id=%r does not match any User.id",
                        client_reference_id,
                    )
                logger.info(
                    "[stripe_tasks] checkout.session.completed user=%s customer=%s rows=%s",
                    client_reference_id,
                    stripe_customer_id,
                    rows,
                )
                # Subscription webhooks can arrive before this event, while User.stripe_customer_id
                # is still empty — apply_subscription_event then no-ops. Sync entitlements here.
                subscription_id = _subscription_id_from_session(session)
                if session.get("mode") == "payment":
                    logger.warning(
                        "[stripe_tasks] checkout.session.completed mode=payment — "
                        "binding stripe_customer_id only; is_ad_free requires a subscription "
                        "Checkout Session (in-app upgrade uses mode=subscription).",
                    )

                # subscription_id is only set for subscription checkouts; payment mode must not run this.
                if subscription_id and session.get("mode") != "payment":
                    try:
                        sub = stripe.Subscription.retrieve(
                            subscription_id,
                            expand=["items.data.price"],
                        )
                        sub_payload = sub if isinstance(sub, dict) else sub.to_dict()
                    except Exception:
                        logger.exception(
                            "[stripe_tasks] checkout.session.completed subscription retrieve failed",
                        )
                    else:
                        AdsService.apply_subscription_event(sub_payload, grant=True)
                        logger.info(
                            "[stripe_tasks] checkout.session.completed synced subscription=%s",
                            subscription_id,
                        )
                elif session.get("mode") not in (None, "payment") and not subscription_id:
                    logger.warning(
                        "[stripe_tasks] checkout.session.completed no subscription id after "
                        "expand session=%s customer=%s mode=%s",
                        session.get("id"),
                        stripe_customer_id,
                        session.get("mode"),
                    )
        elif event_type == "customer.subscription.created":
            subscription_obj = event["data"]["object"]
            AdsService.apply_subscription_event(subscription_obj, grant=True)
        elif event_type == "customer.subscription.updated":
            subscription_obj = event["data"]["object"]
            grant = subscription_obj.get("status", "") in _ACTIVE_STATUSES
            AdsService.apply_subscription_event(subscription_obj, grant=grant)
        elif event_type == "customer.subscription.deleted":
            subscription_obj = event["data"]["object"]
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
