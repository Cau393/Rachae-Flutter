import hashlib
import hmac
import time

from django.conf import settings
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.ads.serializers import (
    AdsStatusSerializer,
    CheckoutSessionResponseSerializer,
    CreateCheckoutSessionSerializer,
    PortalSessionResponseSerializer,
)
from apps.ads.services import AdsService
from apps.users.permissions import ActiveUserPermission


def _response_data(payload, *, status_code=status.HTTP_200_OK):
    return Response({"data": payload}, status=status_code)


class AdsStatusView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        payload = AdsStatusSerializer(AdsService.get_status(request.user)).data
        return _response_data(payload)


class AdsSyncView(APIView):
    """Actively pulls the caller's entitlement from RevenueCat and applies it
    synchronously, then returns the fresh status. Used by the app right after
    a purchase/restore or when resuming from a Stripe Checkout redirect, so
    the UI does not have to wait for a webhook to land.
    """

    permission_classes = [ActiveUserPermission]

    def post(self, request):
        payload = AdsService.sync_revenuecat_status(request.user)
        return _response_data(AdsStatusSerializer(payload).data)


class CreateCheckoutSessionView(APIView):
    permission_classes = [ActiveUserPermission]

    def post(self, request):
        serializer = CreateCheckoutSessionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            result = AdsService.create_checkout_session(
                request.user,
                plan=serializer.validated_data["plan"],
            )
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(
            CheckoutSessionResponseSerializer(result).data,
            status_code=status.HTTP_201_CREATED,
        )


class CreatePortalSessionView(APIView):
    permission_classes = [ActiveUserPermission]

    def post(self, request):
        try:
            result = AdsService.create_portal_session(request.user)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(PortalSessionResponseSerializer(result).data)


class StripeWebhookView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        sig_header = request.META.get("HTTP_STRIPE_SIGNATURE", "")
        AdsService.process_stripe_event(request.body, sig_header)
        return Response({"received": True}, status=status.HTTP_200_OK)


def _valid_rc_hmac_signature(raw_body: bytes, header: str, secret: str) -> bool:
    """Verify RevenueCat's HMAC webhook signing header.

    Format: ``t=<unix_timestamp>,v1=<hex hmac_sha256("{t}.{raw_body}")>``,
    signed with the integration's signing secret. The raw body bytes must be
    used as received — re-serialized JSON would not match.
    """
    parts = dict(p.split("=", 1) for p in header.split(",") if "=" in p)
    timestamp = parts.get("t", "")
    signature = parts.get("v1", "")
    if not timestamp or not signature:
        return False
    try:
        if abs(time.time() - int(timestamp)) > 300:
            return False
    except ValueError:
        return False
    expected = hmac.new(
        secret.encode(), f"{timestamp}.".encode() + raw_body, hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)


class RevenueCatWebhookView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        secret = (getattr(settings, "REVENUECAT_WEBHOOK_SECRET", None) or "").strip()
        if not secret:
            # Fail closed: without a configured secret this endpoint would
            # accept unauthenticated grants/revokes for arbitrary users.
            return Response(
                {"detail": "Webhook not configured"},
                status=status.HTTP_401_UNAUTHORIZED,
            )
        # One secret, two accepted mechanisms: the dashboard "Authorization
        # header value" (static bearer) or HMAC webhook signing. `request.body`
        # must be read before `request.data` parses the stream.
        raw_body = request.body
        auth = (request.META.get("HTTP_AUTHORIZATION") or "").strip()
        sig_header = (
            request.META.get("HTTP_X_REVENUECAT_WEBHOOK_SIGNATURE") or ""
        ).strip()
        authorized = (
            auth
            and (
                hmac.compare_digest(auth, f"Bearer {secret}")
                or hmac.compare_digest(auth, secret)
            )
        ) or (sig_header and _valid_rc_hmac_signature(raw_body, sig_header, secret))
        if not authorized:
            return Response(
                {"detail": "Unauthorized"},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        payload = dict(request.data) if hasattr(request.data, "keys") else request.data
        if not isinstance(payload, dict):
            payload = {}

        AdsService.process_rc_event(payload)
        return Response({"received": True}, status=status.HTTP_200_OK)
