from rest_framework.permissions import BasePermission

from apps.groups.models import GroupMember, GroupRole


def _get_membership(user, group):
    """Return the membership record for a user in a group, if any."""
    return GroupMember.objects.filter(group=group, user=user, is_deleted=False).first()


class IsMemberOrAdmin(BasePermission):
    """Allow MEMBER and ADMIN roles only."""

    message = "You must be a member of this group."

    def has_object_permission(self, request, view, obj):
        membership = _get_membership(request.user, obj)
        if not membership:
            return False
        return membership.role in (GroupRole.MEMBER, GroupRole.ADMIN)


class IsGroupAdmin(BasePermission):
    """Allow ADMIN role only."""

    message = "You must be an admin of this group."

    def has_object_permission(self, request, view, obj):
        membership = _get_membership(request.user, obj)
        if not membership:
            return False
        return membership.role == GroupRole.ADMIN


class IsGroupMemberAny(BasePermission):
    """Allow any membership role: ADMIN, MEMBER, or VIEWER."""

    message = "You must be a member of this group."

    def has_object_permission(self, request, view, obj):
        return GroupMember.objects.filter(group=obj, user=request.user, is_deleted=False).exists()
