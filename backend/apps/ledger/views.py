import uuid

from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
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


class LedgerActivityView(APIView):
    """Dashboard feed: GET /ledger/activity/?page=&limit=&group_id="""

    permission_classes = [ActiveUserPermission]
    _max_limit = 50

    def get(self, request):
        raw_page = request.query_params.get("page", "1")
        raw_limit = request.query_params.get("limit", "20")
        try:
            page = int(raw_page)
            limit = int(raw_limit)
        except (TypeError, ValueError) as exc:
            raise ValidationError("page and limit must be integers.") from exc
        if page < 1:
            raise ValidationError("page must be >= 1.")
        if limit < 1:
            raise ValidationError("limit must be >= 1.")
        limit = min(limit, self._max_limit)

        group_uuid = None
        group_id_param = request.query_params.get("group_id")
        if group_id_param:
            try:
                group_uuid = uuid.UUID(str(group_id_param))
            except (ValueError, TypeError, AttributeError) as exc:
                raise ValidationError("group_id must be a valid UUID.") from exc
            get_object_or_404(Group, id=group_uuid, is_deleted=False)
            membership = GroupMember.objects.filter(
                group_id=group_uuid,
                user=request.user,
                is_deleted=False,
            ).first()
            if membership is None:
                raise PermissionDenied("You must be a member of this group.")

        activities = ActivityService.get_user_activity_feed(
            request.user,
            group_id=group_uuid,
            page=page,
            limit=limit,
        )
        serializer = ActivityFeedResponseSerializer({"activities": activities})
        return _response_data(serializer.data)
