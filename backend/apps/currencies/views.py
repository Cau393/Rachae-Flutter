from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.currencies.serializers import (
    ConvertResultSerializer,
    ExchangeRateRowSerializer,
    SupportedCurrencySerializer,
)
from apps.currencies.services import CurrencyService
from apps.users.permissions import ActiveUserPermission


class SupportedCurrenciesView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        rows = CurrencyService.list_supported()
        serializer = SupportedCurrencySerializer(rows, many=True)
        return Response({"data": serializer.data})


class ExchangeRatesView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        base = request.query_params.get("base", "BRL")
        rows = CurrencyService.latest_rates_for_base(base)
        serializer = ExchangeRateRowSerializer(rows, many=True)
        return Response({"data": serializer.data})


class ConvertCurrencyView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        from_code = request.query_params.get("from")
        to_code = request.query_params.get("to")
        amount = request.query_params.get("amount")
        if amount is None or from_code is None or to_code is None:
            raise ValidationError("Query parameters from, to, and amount are required.")
        try:
            payload = CurrencyService.convert(
                from_currency=from_code,
                to_currency=to_code,
                amount=amount,
            )
        except ValueError as exc:
            return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
        serializer = ConvertResultSerializer(payload)
        return Response({"data": serializer.data})
