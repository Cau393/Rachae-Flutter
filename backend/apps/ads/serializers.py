from rest_framework import serializers


class AdsStatusSerializer(serializers.Serializer):
    is_ad_free = serializers.BooleanField()
    subscription_status = serializers.CharField(allow_null=True)
    plan_expires_at = serializers.DateTimeField(allow_null=True)
    plan_type = serializers.CharField(allow_null=True)


class CreateCheckoutSessionSerializer(serializers.Serializer):
    plan = serializers.ChoiceField(choices=["monthly", "yearly"])


class CheckoutSessionResponseSerializer(serializers.Serializer):
    checkout_url = serializers.URLField()


class PortalSessionResponseSerializer(serializers.Serializer):
    portal_url = serializers.URLField()
