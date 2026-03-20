from django.db import transaction as db_transaction
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

        if not request.user.stripe_customer_id:
            from tasks.stripe_tasks import create_stripe_customer

            db_transaction.on_commit(lambda: create_stripe_customer.delay(str(request.user.id)))

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
        payload = request.body
        sig_header = request.META.get("HTTP_STRIPE_SIGNATURE", "")
        from tasks.stripe_tasks import process_stripe_webhook

        process_stripe_webhook.delay(payload, sig_header)
        return Response({"received": True}, status=status.HTTP_200_OK)
