import logging

import stripe
from django.conf import settings


logger = logging.getLogger(__name__)
stripe.api_key = settings.STRIPE_SECRET_KEY

_ACTIVE_STATUSES = {"active", "trialing"}


class AdsService:
    @staticmethod
    def get_status(user) -> dict:
        return {
            "is_ad_free": user.is_ad_free,
            "subscription_status": user.subscription_status,
            "plan_expires_at": user.plan_expires_at,
            "plan_type": user.plan_type,
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
        return {"checkout_url": session.url}

    @staticmethod
    def create_portal_session(user) -> dict:
        if not user.stripe_customer_id:
            raise ValueError("No active subscription found.")

        frontend_url = getattr(settings, "FRONTEND_URL", "https://app.rachae.app")
        session = stripe.billing_portal.Session.create(
            customer=user.stripe_customer_id,
            return_url=f"{frontend_url}/profile",
        )
        return {"portal_url": session.url}

    @staticmethod
    def apply_subscription_event(subscription_obj: dict, grant: bool) -> None:
        from datetime import datetime, timezone as tz

        from apps.users.models import User

        customer_id = subscription_obj.get("customer")
        try:
            user = User.objects.get(stripe_customer_id=customer_id)
        except User.DoesNotExist:
            logger.warning("[AdsService] no user for customer=%s", customer_id)
            return

        status = subscription_obj.get("status", "")
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
        user.subscription_status = status
        user.plan_type = plan_type if grant else None
        user.plan_expires_at = plan_expires_at
        user.save(update_fields=["is_ad_free", "subscription_status", "plan_type", "plan_expires_at"])

        logger.info(
            "[AdsService] apply_subscription_event: user=%s status=%s is_ad_free=%s",
            user.id,
            status,
            user.is_ad_free,
        )
