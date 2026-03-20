from rest_framework.permissions import BasePermission


class ActiveUserPermission(BasePermission):
    message = "This user account is not active."

    def has_permission(self, request, view):
        user = getattr(request, "user", None)
        return bool(user and user.is_authenticated and not user.is_deleted)
