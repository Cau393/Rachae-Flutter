import base64

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
        # JSON-encode raw body for Celery: bytes do not round-trip through the JSON
        # task serializer, which breaks Stripe signature verification.
        payload_b64 = base64.b64encode(request.body).decode("ascii")
        sig_header = request.META.get("HTTP_STRIPE_SIGNATURE", "")
        from tasks.stripe_tasks import process_stripe_webhook

        process_stripe_webhook.delay(payload_b64, sig_header)
        return Response({"received": True}, status=status.HTTP_200_OK)


class RevenueCatWebhookView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        secret = (getattr(settings, "REVENUECAT_WEBHOOK_SECRET", None) or "").strip()
        if secret:
            auth = (request.META.get("HTTP_AUTHORIZATION") or "").strip()
            if auth != f"Bearer {secret}" and auth != secret:
                return Response(
                    {"detail": "Unauthorized"},
                    status=status.HTTP_401_UNAUTHORIZED,
                )

        payload = dict(request.data) if hasattr(request.data, "keys") else request.data
        if not isinstance(payload, dict):
            payload = {}

        from tasks.revenuecat_tasks import process_rc_webhook

        process_rc_webhook.delay(payload)
        return Response({"received": True}, status=status.HTTP_200_OK)
