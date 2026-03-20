from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.groups.models import Group, GroupRole
from apps.groups.queries import get_membership
from apps.groups.serializers import (
    AddMemberSerializer,
    BalancesSerializer,
    GroupCreateSerializer,
    GroupDetailSerializer,
    GroupListSerializer,
    GroupMemberSerializer,
    GroupReportQuerySerializer,
    GroupReportSerializer,
    GroupUpdateSerializer,
    MemberRoleChangeSerializer,
    SimplifiedBalancesSerializer,
)
from apps.groups.services import BalanceService, GroupService, MemberService, ReportService
from apps.users.permissions import ActiveUserPermission

ROLE_HIERARCHY = {
    GroupRole.VIEWER: 1,
    GroupRole.MEMBER: 2,
    GroupRole.ADMIN: 3,
}


def _require_role(user, group: Group, min_role: str):
    membership = get_membership(user, group)
    if not membership:
        raise PermissionDenied("You must be a member of this group.")

    if ROLE_HIERARCHY[membership.role] < ROLE_HIERARCHY[min_role]:
        if min_role == GroupRole.ADMIN:
            raise PermissionDenied("You must be an admin of this group.")
        raise PermissionDenied("You must be a member of this group.")

    return membership


class GroupBaseView(APIView):
    permission_classes = [ActiveUserPermission]

    def get_group(self, request, group_id, min_role: str = GroupRole.MEMBER) -> Group:
        group = get_object_or_404(Group, id=group_id, is_deleted=False)
        _require_role(request.user, group, min_role)
        return group


class GroupListCreateView(GroupBaseView):
    def get(self, request):
        groups = GroupService.list_for_user(request.user)
        return Response(GroupListSerializer(groups, many=True).data)

    def post(self, request):
        serializer = GroupCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            group = GroupService.create_group(request.user, serializer.validated_data.copy())
            group = GroupService.get_detail(group, request.user)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return Response(GroupDetailSerializer(group).data, status=status.HTTP_201_CREATED)


class GroupDetailView(GroupBaseView):
    def get(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.VIEWER)
        group = GroupService.get_detail(group, request.user)
        return Response(GroupDetailSerializer(group).data)

    def patch(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.ADMIN)
        serializer = GroupUpdateSerializer(group, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)

        try:
            group = GroupService.update_group(group, serializer.validated_data)
            group = GroupService.get_detail(group, request.user)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return Response(GroupDetailSerializer(group).data)

    def delete(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.ADMIN)
        GroupService.delete_group(group, request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class GroupMemberListView(GroupBaseView):
    def get(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.VIEWER)
        memberships = MemberService.list_members(group)
        return Response(GroupMemberSerializer(memberships, many=True).data)

    def post(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.ADMIN)
        serializer = AddMemberSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            membership = MemberService.add_member(
                group,
                serializer.validated_data["user_id"],
                serializer.validated_data["role"],
                request.user,
            )
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return Response(GroupMemberSerializer(membership).data, status=status.HTTP_201_CREATED)


class GroupMemberDetailView(GroupBaseView):
    def patch(self, request, group_id, user_id):
        group = self.get_group(request, group_id, GroupRole.ADMIN)
        serializer = MemberRoleChangeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            membership = MemberService.change_role(
                group,
                user_id,
                serializer.validated_data["role"],
                actor=request.user,
            )
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return Response(GroupMemberSerializer(membership).data)

    def delete(self, request, group_id, user_id):
        group = self.get_group(request, group_id, GroupRole.ADMIN)

        try:
            MemberService.remove_member(group, user_id, request.user)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return Response(status=status.HTTP_204_NO_CONTENT)


class GroupLeaveView(GroupBaseView):
    def post(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.MEMBER)

        try:
            MemberService.leave_group(group, request.user)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return Response(status=status.HTTP_204_NO_CONTENT)


class GroupBalancesView(GroupBaseView):
    def get(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.VIEWER)
        payload = BalanceService.group_balances(group)
        return Response(BalancesSerializer(payload).data)


class GroupSimplifiedBalancesView(GroupBaseView):
    def get(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.VIEWER)
        payload = BalanceService.simplified_balances(group)
        return Response(SimplifiedBalancesSerializer(payload).data)


class GroupReportView(GroupBaseView):
    def get(self, request, group_id):
        group = self.get_group(request, group_id, GroupRole.VIEWER)
        query_serializer = GroupReportQuerySerializer(
            data={
                "from_date": request.query_params.get("from"),
                "to_date": request.query_params.get("to"),
            }
        )
        query_serializer.is_valid(raise_exception=True)

        payload = ReportService.group_report(
            group,
            date_from=query_serializer.validated_data.get("from"),
            date_to=query_serializer.validated_data.get("to"),
        )
        return Response(GroupReportSerializer(payload).data)
