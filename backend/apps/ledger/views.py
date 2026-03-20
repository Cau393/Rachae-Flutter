from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import PermissionDenied
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.groups.models import Group, GroupMember
from apps.ledger.serializers import (
    ActivityFeedResponseSerializer,
    GroupBalancesResponseSerializer,
    SimplifiedBalancesResponseSerializer,
)
from apps.ledger.services import ActivityService, LedgerService
from apps.users.permissions import ActiveUserPermission


def _response_data(payload, *, status_code=status.HTTP_200_OK):
    return Response({"data": payload}, status=status_code)


class LedgerBaseView(APIView):
    permission_classes = [ActiveUserPermission]

    def get_group(self, request, group_id) -> Group:
        group = get_object_or_404(Group, id=group_id, is_deleted=False)
        membership = GroupMember.objects.filter(
            group=group,
            user=request.user,
            is_deleted=False,
        ).first()
        if membership is None:
            raise PermissionDenied("You must be a member of this group.")
        return group


class GroupBalancesView(LedgerBaseView):
    def get(self, request, group_id):
        group = self.get_group(request, group_id)
        payload = LedgerService.get_group_balances(group.id)
        serializer = GroupBalancesResponseSerializer(payload)
        return _response_data(serializer.data)


class GroupSimplifiedBalancesView(LedgerBaseView):
    def get(self, request, group_id):
        group = self.get_group(request, group_id)
        payload = LedgerService.get_simplified_balances(group)
        serializer = SimplifiedBalancesResponseSerializer(payload)
        return _response_data(serializer.data)


class GroupActivityView(LedgerBaseView):
    def get(self, request, group_id):
        group = self.get_group(request, group_id)
        payload = {"activities": ActivityService.get_group_activity(group.id)}
        serializer = ActivityFeedResponseSerializer(payload)
        return _response_data(serializer.data)
