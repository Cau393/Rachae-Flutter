from django.core.management.base import BaseCommand, CommandError

from apps.users.models import User


class Command(BaseCommand):
    help = (
        "Reset a single user's subscription/entitlement state for re-testing "
        "(e.g. re-testing iOS IAP in production). Clears is_ad_free, "
        "subscription_status, plan_type, and plan_expires_at. Pass --clear-stripe "
        "to also clear stripe_customer_id, which is required to un-block RevenueCat "
        "sync when the cross-provider guard in apps.ads.services is ignoring RC "
        "webhooks because a stale Stripe customer id is set."
    )

    def add_arguments(self, parser):
        parser.add_argument("email", type=str, help="Email of the user to reset (case-insensitive).")
        parser.add_argument(
            "--clear-stripe",
            action="store_true",
            help="Also clear stripe_customer_id. Needed to unblock RevenueCat sync "
            "for a user previously billed via Stripe.",
        )

    def handle(self, *args, **options):
        email = options["email"]
        clear_stripe = options["clear_stripe"]

        try:
            user = User.objects.get(email__iexact=email)
        except User.DoesNotExist as exc:
            raise CommandError(f"No active user found with email '{email}'.") from exc

        self.stdout.write(f"Resetting entitlement state for user {user.id} ({user.email})")
        self.stdout.write("Before:")
        self.stdout.write(f"  is_ad_free={user.is_ad_free!r}")
        self.stdout.write(f"  subscription_status={user.subscription_status!r}")
        self.stdout.write(f"  plan_type={user.plan_type!r}")
        self.stdout.write(f"  plan_expires_at={user.plan_expires_at!r}")
        self.stdout.write(f"  stripe_customer_id={user.stripe_customer_id!r}")

        user.is_ad_free = False
        user.subscription_status = None
        user.plan_type = None
        user.plan_expires_at = None
        update_fields = ["is_ad_free", "subscription_status", "plan_type", "plan_expires_at"]

        if clear_stripe:
            user.stripe_customer_id = None
            update_fields.append("stripe_customer_id")

        user.save(update_fields=update_fields)

        self.stdout.write("After:")
        self.stdout.write(f"  is_ad_free={user.is_ad_free!r}")
        self.stdout.write(f"  subscription_status={user.subscription_status!r}")
        self.stdout.write(f"  plan_type={user.plan_type!r}")
        self.stdout.write(f"  plan_expires_at={user.plan_expires_at!r}")
        self.stdout.write(f"  stripe_customer_id={user.stripe_customer_id!r}")

        self.stdout.write(self.style.SUCCESS(f"Entitlement state reset for {user.email}."))
