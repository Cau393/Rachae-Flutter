from rest_framework.permissions import BasePermission

from apps.groups.models import GroupMember, GroupRole


def _get_group_membership(user, group_id):
    """Return the active membership for a user in a group, if any."""
    if not group_id:
        return None

    return GroupMember.objects.filter(
        group_id=group_id,
        user=user,
        is_deleted=False,
    ).first()


class IsInvolved(BasePermission):
    """
    Allow access when the user is involved in the expense.

    INVOLVED means the user is a member of the expense group, the payer,
    the creator, or one of the split participants.
    """

    message = "You are not involved in this expense."

    def has_object_permission(self, request, view, obj):
        if _get_group_membership(request.user, obj.group_id):
            return True

        return (
            obj.paid_by_id == request.user.id
            or obj.created_by_id == request.user.id
            or obj.splits.filter(user=request.user).exists()
        )


class IsCreatorOrGroupAdmin(BasePermission):
    """
    Allow access to the expense creator or an admin of the expense group.
    """

    message = "You must be the creator or a group admin to modify this expense."

    def has_object_permission(self, request, view, obj):
        if obj.created_by_id == request.user.id:
            return True

        membership = _get_group_membership(request.user, obj.group_id)
        if not membership:
            return False

        return membership.role == GroupRole.ADMIN
