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

        AdsService.process_rc_event(payload)
        return Response({"received": True}, status=status.HTTP_200_OK)
