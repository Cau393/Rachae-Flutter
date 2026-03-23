from rest_framework import serializers


class BalanceSerializer(serializers.Serializer):
    user_id = serializers.UUIDField()
    user_name = serializers.CharField()
    balance = serializers.DecimalField(max_digits=12, decimal_places=2)


class GroupBalancesResponseSerializer(serializers.Serializer):
    balances = BalanceSerializer(many=True)


class SimplifiedSuggestionSerializer(serializers.Serializer):
    payer_id = serializers.UUIDField()
    payer_name = serializers.CharField()
    receiver_id = serializers.UUIDField()
    receiver_name = serializers.CharField()
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = serializers.CharField(max_length=3)


class SimplifiedBalancesResponseSerializer(serializers.Serializer):
    simplify_debts = serializers.BooleanField()
    suggestions = SimplifiedSuggestionSerializer(many=True)


class ActivityItemSerializer(serializers.Serializer):
    type = serializers.ChoiceField(choices=["expense", "transaction"])
    id = serializers.UUIDField()
    group_id = serializers.UUIDField(allow_null=True)
    group_name = serializers.CharField(required=False, allow_null=True)
    amount = serializers.DecimalField(max_digits=12, decimal_places=2)
    currency = serializers.CharField(max_length=3)
    created_at = serializers.DateTimeField()

    description = serializers.CharField(required=False, allow_null=True)
    paid_by_id = serializers.UUIDField(required=False, allow_null=True)
    paid_by_name = serializers.CharField(required=False, allow_null=True)

    payer_id = serializers.UUIDField(required=False, allow_null=True)
    payer_name = serializers.CharField(required=False, allow_null=True)
    receiver_id = serializers.UUIDField(required=False, allow_null=True)
    receiver_name = serializers.CharField(required=False, allow_null=True)
    note = serializers.CharField(required=False, allow_null=True)
    is_confirmed = serializers.BooleanField(required=False, allow_null=True)


class ActivityFeedResponseSerializer(serializers.Serializer):
    activities = ActivityItemSerializer(many=True)
