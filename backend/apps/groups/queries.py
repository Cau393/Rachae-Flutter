from apps.groups.models import Group, GroupMember, GroupRole


def get_user_groups(user):
    """Return all non-deleted groups where the user is a member."""
    return (
        Group.objects.filter(members__user=user, members__is_deleted=False, is_deleted=False)
        .select_related("created_by")
        .prefetch_related("members__user")
        .distinct()
    )


def get_group_members(group):
    """Return all memberships for a group with related user data."""
    return GroupMember.objects.filter(group=group, is_deleted=False).select_related("user", "invited_by")


def get_membership(user, group):
    """Return a single membership record or None."""
    return GroupMember.objects.filter(user=user, group=group, is_deleted=False).first()


def admin_count(group):
    """Return the number of admin memberships in a group."""
    return GroupMember.objects.filter(group=group, role=GroupRole.ADMIN, is_deleted=False).count()
