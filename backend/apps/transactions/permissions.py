from rest_framework.permissions import BasePermission


class IsInvolvedInTransaction(BasePermission):
    """Allows access if user is the payer or receiver."""

    message = "You are not involved in this transaction."

    def has_object_permission(self, request, view, obj):
        return obj.payer_id == request.user.id or obj.receiver_id == request.user.id


class IsTransactionReceiver(BasePermission):
    """Allows access only to the receiver."""

    message = "Only the receiver can perform this action."

    def has_object_permission(self, request, view, obj):
        return obj.receiver_id == request.user.id
