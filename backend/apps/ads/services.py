import logging

import requests
import stripe
from django.conf import settings


logger = logging.getLogger(__name__)
stripe.api_key = settings.STRIPE_SECRET_KEY

_ACTIVE_STATUSES = {"active", "trialing"}
_RC_GRANT_TYPES = frozenset({"INITIAL_PURCHASE", "RENEWAL", "PRODUCT_CHANGE"})
_RC_REVOKE_TYPES = frozenset({"CANCELLATION", "EXPIRATION"})
_REVENUECAT_API_BASE = "https://api.revenuecat.com/v1"


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
            "[AdsService] checkout.session.completed PaymentIntent.retrieve(%s) failed",
            pi_id,
        )
        return None


def _plan_type_from_rc_event(event: dict) -> str | None:
    # PRODUCT_CHANGE carries the OLD product in `product_id` and the new one in
    # `new_product_id` — prefer the new product so plan switches persist.
    pid = str(event.get("new_product_id") or event.get("product_id") or "").lower()
    if any(
        s in pid
        for s in (
            "lifetime",
            "life_time",
            "non_renewing",
            "nonrenewing",
            "one_time",
            "onetime",
        )
    ):
        return "lifetime"
    if any(s in pid for s in ("year", "annual", "yr")):
        return "yearly"
    if any(s in pid for s in ("month", "monthly")):
        return "monthly"
    period = str(event.get("period_type") or "").upper()
    if period in ("YEARLY", "ANNUAL"):
        return "yearly"
    if period in ("MONTHLY", "NORMAL"):
        return "monthly"
    return None


def _expires_from_rc_event(event: dict):
    from datetime import datetime, timezone as tz

    raw = event.get("expiration_at_ms")
    if raw is None:
        return None
    try:
        return datetime.fromtimestamp(int(raw) / 1000.0, tz=tz.utc)
    except (TypeError, ValueError, OSError):
        return None


def _plan_type_from_rc_entitlement(entitlement: dict) -> str | None:
    pid = str(entitlement.get("product_identifier") or "").lower()
    if any(
        s in pid
        for s in (
            "lifetime",
            "life_time",
            "non_renewing",
            "nonrenewing",
            "one_time",
            "onetime",
        )
    ):
        return "lifetime"
    if any(s in pid for s in ("year", "annual", "yr")):
        return "yearly"
    if any(s in pid for s in ("month", "monthly")):
        return "monthly"
    return None


def _expires_from_rc_entitlement(entitlement: dict):
    from datetime import datetime, timezone as tz

    raw = entitlement.get("expires_date")
    if not raw:
        return None
    try:
        return datetime.fromisoformat(str(raw).replace("Z", "+00:00")).astimezone(tz.utc)
    except (TypeError, ValueError):
        return None


class AdsService:
    @staticmethod
    def get_status(user) -> dict:
        return {
            "is_ad_free": user.is_ad_free,
            "subscription_status": user.subscription_status,
            "plan_expires_at": user.plan_expires_at,
            "plan_type": user.plan_type,
            "stripe_portal_available": bool(user.stripe_customer_id),
        }

    @staticmethod
    def create_checkout_session(user, plan: str) -> dict:
        if user.is_ad_free and user.subscription_status in _ACTIVE_STATUSES:
            raise ValueError("You already have an active subscription.")

        if plan == "monthly":
            price_id = settings.STRIPE_PRICE_MONTHLY
        elif plan == "yearly":
            price_id = settings.STRIPE_PRICE_YEARLY
        else:
            raise ValueError(f"Invalid plan '{plan}'. Must be 'monthly' or 'yearly'.")

        if not price_id:
            raise ValueError(f"STRIPE_PRICE_{plan.upper()} is not configured in settings.")

        frontend_url = getattr(settings, "FRONTEND_URL", "https://app.rachae.app")
        try:
            session = stripe.checkout.Session.create(
                customer=user.stripe_customer_id or None,
                customer_email=None if user.stripe_customer_id else user.email,
                mode="subscription",
                line_items=[{"price": price_id, "quantity": 1}],
                success_url=f"{frontend_url}/profile?subscription=success",
                cancel_url=f"{frontend_url}/profile?subscription=canceled",
                client_reference_id=str(user.id),
                metadata={"user_id": str(user.id), "plan": plan},
            )
        except stripe.error.StripeError as exc:
            # e.g. live account not activated yet ("No valid payment method
            # types") — a config problem, not a server fault: surface as 400.
            logger.exception(
                "[AdsService] create_checkout_session: Stripe rejected the "
                "request for user=%s plan=%s",
                user.id,
                plan,
            )
            raise ValueError("Could not start checkout with the payment provider.") from exc
        return {"checkout_url": session.url}

    @staticmethod
    def create_portal_session(user) -> dict:
        if not user.stripe_customer_id:
            raise ValueError("No active subscription found.")

        frontend_url = getattr(settings, "FRONTEND_URL", "https://app.rachae.app")
        try:
            session = stripe.billing_portal.Session.create(
                customer=user.stripe_customer_id,
                return_url=f"{frontend_url}/profile",
            )
        except stripe.error.StripeError as exc:
            logger.exception(
                "[AdsService] create_portal_session: Stripe rejected the "
                "request for user=%s",
                user.id,
            )
            raise ValueError("Could not open the subscription portal.") from exc
        return {"portal_url": session.url}

    @staticmethod
    def apply_subscription_event(subscription_obj: dict, grant: bool) -> None:
        from datetime import datetime, timezone as tz

        from apps.users.models import User

        raw_customer = subscription_obj.get("customer")
        customer_id = (
            raw_customer
            if isinstance(raw_customer, str)
            else (raw_customer or {}).get("id")
        )
        if not customer_id:
            logger.warning("[AdsService] subscription webhook missing customer id")
            return
        try:
            user = User.objects.get(stripe_customer_id=customer_id)
        except User.DoesNotExist:
            logger.warning(
                "Received subscription webhook for unknown Stripe Customer: %s",
                customer_id,
            )
            return

        status = subscription_obj.get("status", "")
        # Stripe keeps status="active" when the user cancels at period end;
        # surface it as "canceled" so the app can show the cancelled state
        # while access remains valid until current_period_end.
        cancel_at_period_end = bool(subscription_obj.get("cancel_at_period_end"))
        display_status = "canceled" if (cancel_at_period_end and status in _ACTIVE_STATUSES) else status
        try:
            price_id = subscription_obj["items"]["data"][0]["price"]["id"]
            if price_id == settings.STRIPE_PRICE_MONTHLY:
                plan_type = "monthly"
            elif price_id == settings.STRIPE_PRICE_YEARLY:
                plan_type = "yearly"
            else:
                plan_type = None
        except (KeyError, IndexError):
            plan_type = None

        period_end = subscription_obj.get("current_period_end")
        plan_expires_at = datetime.fromtimestamp(period_end, tz=tz.utc) if period_end and grant else None

        user.is_ad_free = grant and (status in _ACTIVE_STATUSES)
        user.subscription_status = display_status
        user.plan_type = plan_type if grant else None
        user.plan_expires_at = plan_expires_at
        user.save(update_fields=["is_ad_free", "subscription_status", "plan_type", "plan_expires_at"])

        logger.info(
            "[AdsService] apply_subscription_event: user=%s status=%s is_ad_free=%s",
            user.id,
            status,
            user.is_ad_free,
        )

    @staticmethod
    def apply_revenuecat_entitlement(
        user,
        *,
        grant: bool,
        subscription_status: str | None,
        plan_expires_at,
        plan_type: str | None,
    ) -> None:
        user.is_ad_free = grant
        user.subscription_status = subscription_status
        if grant:
            user.plan_type = plan_type
            user.plan_expires_at = plan_expires_at
        else:
            user.plan_type = None
            user.plan_expires_at = None
        user.save(
            update_fields=[
                "is_ad_free",
                "subscription_status",
                "plan_type",
                "plan_expires_at",
            ]
        )
        logger.info(
            "[AdsService] apply_revenuecat_entitlement: user=%s grant=%s status=%s",
            user.id,
            grant,
            subscription_status,
        )

    @staticmethod
    def process_stripe_event(payload_bytes: bytes, sig_header: str) -> None:
        """Verify and apply a Stripe webhook event synchronously.

        Called in-request by StripeWebhookView so is_ad_free updates land
        before the 200 response, and by the Celery task wrapper for retries.
        """
        try:
            event = stripe.Webhook.construct_event(
                payload_bytes,
                sig_header,
                settings.STRIPE_WEBHOOK_SECRET,
            )
        except stripe.error.SignatureVerificationError as exc:
            logger.error("[AdsService] invalid Stripe webhook signature: %s", exc)
            return

        event_type = event["type"]
        logger.info("[AdsService] stripe event_type=%s", event_type)

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
                        "[AdsService] checkout.session.completed Session.retrieve(%s) failed",
                        session_id,
                    )

            client_reference_id = session.get("client_reference_id")
            stripe_customer_id = _resolve_stripe_customer_id_from_session(session, stripe)

            if not client_reference_id:
                logger.warning(
                    "[AdsService] checkout.session.completed missing client_reference_id "
                    "session_id=%r — ensure Checkout Session.create sets client_reference_id",
                    session_id,
                )
            elif not stripe_customer_id:
                logger.warning(
                    "[AdsService] checkout.session.completed missing customer id "
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
                        "[AdsService] checkout.session.completed zero rows updated — "
                        "client_reference_id=%r does not match any User.id",
                        client_reference_id,
                    )
                logger.info(
                    "[AdsService] checkout.session.completed user=%s customer=%s rows=%s",
                    client_reference_id,
                    stripe_customer_id,
                    rows,
                )
                # Subscription webhooks can arrive before this event, while User.stripe_customer_id
                # is still empty — apply_subscription_event then no-ops. Sync entitlements here.
                subscription_id = _subscription_id_from_session(session)
                if session.get("mode") == "payment":
                    logger.warning(
                        "[AdsService] checkout.session.completed mode=payment — "
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
                            "[AdsService] checkout.session.completed subscription retrieve failed",
                        )
                    else:
                        AdsService.apply_subscription_event(sub_payload, grant=True)
                        logger.info(
                            "[AdsService] checkout.session.completed synced subscription=%s",
                            subscription_id,
                        )
                elif session.get("mode") not in (None, "payment") and not subscription_id:
                    logger.warning(
                        "[AdsService] checkout.session.completed no subscription id after "
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
            logger.debug("[AdsService] unhandled stripe event_type=%s - ignoring", event_type)

    @staticmethod
    def process_rc_event(payload: dict) -> None:
        """Apply a RevenueCat webhook event synchronously.

        Called in-request by RevenueCatWebhookView so is_ad_free updates land
        before the 200 response, and by the Celery task wrapper for retries.
        """
        from apps.users.models import User

        event = payload.get("event") or {}
        if not isinstance(event, dict):
            event = {}
        event_type = event.get("type") or ""
        app_user_id = event.get("app_user_id")
        if not app_user_id:
            logger.warning("[AdsService] RevenueCat webhook missing app_user_id")
            return

        try:
            user = User.objects.get(id=app_user_id)
        except User.DoesNotExist:
            logger.warning(
                "[AdsService] RevenueCat webhook unknown app_user_id=%s",
                app_user_id,
            )
            return
        except (ValueError, TypeError):
            logger.warning(
                "[AdsService] RevenueCat webhook invalid app_user_id=%r",
                app_user_id,
            )
            return

        plan_type = _plan_type_from_rc_event(event)
        expires = _expires_from_rc_event(event)

        if event_type in _RC_GRANT_TYPES:
            AdsService.apply_revenuecat_entitlement(
                user,
                grant=True,
                subscription_status="active",
                plan_expires_at=expires,
                plan_type=plan_type,
            )
        elif event_type == "CANCELLATION":
            if user.stripe_customer_id:
                # A stale Apple/sandbox cancellation must not flip a
                # Stripe-billed user's status to "canceled" — Stripe webhooks
                # are the authority once a Stripe customer exists. (RC grants
                # stay allowed: blocking them would strand a user who paid via
                # Apple after their Stripe subscription lapsed.)
                logger.info(
                    "[AdsService] RevenueCat CANCELLATION ignored for user=%s "
                    "with Stripe customer",
                    user.id,
                )
                return
            # CANCELLATION only means auto-renew was turned off. The entitlement
            # stays valid until the paid period ends (RevenueCat sends EXPIRATION
            # then). Keep ad-free until the expiry date.
            AdsService.apply_revenuecat_entitlement(
                user,
                grant=True,
                subscription_status="canceled",
                plan_expires_at=expires or user.plan_expires_at,
                plan_type=plan_type or user.plan_type,
            )
        elif event_type in _RC_REVOKE_TYPES:
            if user.stripe_customer_id:
                # Stripe-billed user: an expired Apple/sandbox entitlement must
                # not clobber Stripe-granted state — Stripe webhooks are the
                # authority once a Stripe customer exists.
                logger.info(
                    "[AdsService] RevenueCat %s ignored for user=%s with Stripe customer",
                    event_type,
                    user.id,
                )
                return
            AdsService.apply_revenuecat_entitlement(
                user,
                grant=False,
                subscription_status="expired",
                plan_expires_at=None,
                plan_type=None,
            )
        else:
            logger.debug("[AdsService] ignoring RevenueCat event_type=%s", event_type)

    @staticmethod
    def sync_revenuecat_status(user) -> dict:
        """Query the RevenueCat REST API for `user` and apply the current
        entitlement synchronously, then return the fresh status payload.

        If REVENUECAT_API_KEY is unset, this is a no-op and just returns the
        current DB-backed status (no error).
        """
        api_key = (getattr(settings, "REVENUECAT_API_KEY", None) or "").strip()
        if not api_key:
            return AdsService.get_status(user)

        try:
            response = requests.get(
                f"{_REVENUECAT_API_BASE}/subscribers/{user.id}",
                headers={"Authorization": f"Bearer {api_key}"},
                timeout=10,
            )
            response.raise_for_status()
            body = response.json()
        except Exception:
            logger.exception(
                "[AdsService] sync_revenuecat_status: RevenueCat API call failed for user=%s",
                user.id,
            )
            return AdsService.get_status(user)

        entitlements = (
            body.get("subscriber", {}).get("entitlements", {}) if isinstance(body, dict) else {}
        )
        entitlement = entitlements.get("ad_free") if isinstance(entitlements, dict) else None

        def _rc_status_for(entitlement_obj: dict) -> str:
            """Return "canceled" when auto-renew is off but access remains,
            else "active". RevenueCat exposes this via
            subscriber.subscriptions[product_id].unsubscribe_detected_at."""
            subscriptions = body.get("subscriber", {}).get("subscriptions", {})
            if isinstance(subscriptions, dict):
                sub = subscriptions.get(entitlement_obj.get("product_identifier") or "")
                if isinstance(sub, dict) and sub.get("unsubscribe_detected_at"):
                    return "canceled"
            return "active"

        if isinstance(entitlement, dict) and entitlement.get("expires_date"):
            expires_at = _expires_from_rc_entitlement(entitlement)
            from datetime import datetime, timezone as tz

            is_active = expires_at is None or expires_at > datetime.now(tz.utc)
            if is_active:
                AdsService.apply_revenuecat_entitlement(
                    user,
                    grant=True,
                    subscription_status=_rc_status_for(entitlement),
                    plan_expires_at=expires_at,
                    plan_type=_plan_type_from_rc_entitlement(entitlement),
                )
            elif user.stripe_customer_id:
                # Stripe-billed user: an expired Apple/sandbox entitlement must
                # not clobber Stripe-granted state — Stripe webhooks are the
                # authority once a Stripe customer exists.
                logger.info(
                    "[AdsService] sync_revenuecat_status: expired RC entitlement "
                    "ignored for user=%s with Stripe customer",
                    user.id,
                )
            else:
                AdsService.apply_revenuecat_entitlement(
                    user,
                    grant=False,
                    subscription_status="expired",
                    plan_expires_at=None,
                    plan_type=None,
                )
        elif isinstance(entitlement, dict):
            # Entitlement present with no expiry (e.g. lifetime/non-renewing) is active.
            AdsService.apply_revenuecat_entitlement(
                user,
                grant=True,
                subscription_status="active",
                plan_expires_at=None,
                plan_type=_plan_type_from_rc_entitlement(entitlement),
            )

        return AdsService.get_status(user)
