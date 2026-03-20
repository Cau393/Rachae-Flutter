from django.test import TestCase
from rest_framework.test import APIRequestFactory

from apps.groups.models import GroupRole
from apps.groups.permissions import IsGroupAdmin, IsGroupMemberAny, IsMemberOrAdmin

from .base import GroupTestMixin


class GroupPermissionTests(GroupTestMixin, TestCase):
    def setUp(self):
        super().setUp()
        self.factory = APIRequestFactory()
        self.group = self.create_group()
        self.add_membership(self.group, self.user, GroupRole.ADMIN)
        self.add_membership(self.group, self.member_user, GroupRole.MEMBER)
        self.add_membership(self.group, self.viewer_user, GroupRole.VIEWER)

    def build_request(self, user):
        request = self.factory.get("/")
        request.user = user
        return request

    def test_viewer_can_access_read_only_membership_permission(self):
        request = self.build_request(self.viewer_user)

        self.assertTrue(IsGroupMemberAny().has_object_permission(request, None, self.group))
        self.assertFalse(IsMemberOrAdmin().has_object_permission(request, None, self.group))
        self.assertFalse(IsGroupAdmin().has_object_permission(request, None, self.group))

    def test_member_has_member_plus_access_but_not_admin_access(self):
        request = self.build_request(self.member_user)

        self.assertTrue(IsGroupMemberAny().has_object_permission(request, None, self.group))
        self.assertTrue(IsMemberOrAdmin().has_object_permission(request, None, self.group))
        self.assertFalse(IsGroupAdmin().has_object_permission(request, None, self.group))

    def test_non_member_is_denied_by_all_permissions(self):
        request = self.build_request(self.other_user)

        self.assertFalse(IsGroupMemberAny().has_object_permission(request, None, self.group))
        self.assertFalse(IsMemberOrAdmin().has_object_permission(request, None, self.group))
        self.assertFalse(IsGroupAdmin().has_object_permission(request, None, self.group))

    def test_admin_has_all_group_permissions(self):
        request = self.build_request(self.user)

        self.assertTrue(IsGroupMemberAny().has_object_permission(request, None, self.group))
        self.assertTrue(IsMemberOrAdmin().has_object_permission(request, None, self.group))
        self.assertTrue(IsGroupAdmin().has_object_permission(request, None, self.group))
