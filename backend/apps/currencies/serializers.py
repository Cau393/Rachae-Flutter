from rest_framework import serializers


class SupportedCurrencySerializer(serializers.Serializer):
    code = serializers.CharField(max_length=3)
    name = serializers.CharField()
    symbol = serializers.CharField()


class ExchangeRateRowSerializer(serializers.Serializer):
    base_currency = serializers.CharField(max_length=3)
    quote_currency = serializers.CharField(max_length=3)
    rate = serializers.CharField()
    fetched_at = serializers.DateTimeField()


class ConvertResultSerializer(serializers.Serializer):
    result = serializers.CharField()
    rate = serializers.CharField()
    fetched_at = serializers.DateTimeField()
