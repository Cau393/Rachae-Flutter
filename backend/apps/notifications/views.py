from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.notifications.models import Notification
from apps.notifications.serializers import (
    DeviceTokenRemoveSerializer,
    DeviceTokenSerializer,
    NotificationPreferenceSerializer,
    NotificationSerializer,
)
from apps.notifications.services import (
    DeviceTokenService,
    NotificationService,
    PreferenceService,
)
from apps.users.permissions import ActiveUserPermission


def _response_data(payload, *, status_code=status.HTTP_200_OK):
    return Response({"data": payload}, status=status_code)


class NotificationPagination(PageNumberPagination):
    page_size = 20

    def get_paginated_response(self, data):
        return Response(
            {
                "data": data,
                "pagination": {
                    "count": self.page.paginator.count,
                    "next": self.get_next_link(),
                    "previous": self.get_previous_link(),
                },
            }
        )


class NotificationListView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        qs = (
            Notification.objects.filter(recipient=request.user)
            .select_related("actor")
            .order_by("-created_at")
        )
        paginator = NotificationPagination()
        page = paginator.paginate_queryset(qs, request)
        response = paginator.get_paginated_response(
            NotificationSerializer(page, many=True).data
        )
        response["X-Unread-Count"] = str(NotificationService.unread_count(request.user))
        return response


class NotificationMarkReadView(APIView):
    permission_classes = [ActiveUserPermission]

    def patch(self, request, notification_id):
        notif = get_object_or_404(
            Notification, id=notification_id, recipient=request.user
        )
        NotificationService.mark_read(notif)
        return _response_data(NotificationSerializer(notif).data)


class NotificationMarkAllReadView(APIView):
    permission_classes = [ActiveUserPermission]

    def patch(self, request):
        count = NotificationService.mark_all_read(request.user)
        return _response_data({"marked_read": count})


class NotificationPreferenceView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        pref = PreferenceService.get_or_create(request.user)
        return _response_data(NotificationPreferenceSerializer(pref).data)

    def patch(self, request):
        pref = PreferenceService.get_or_create(request.user)
        serializer = NotificationPreferenceSerializer(
            pref, data=request.data, partial=True
        )
        serializer.is_valid(raise_exception=True)
        PreferenceService.update(pref, serializer.validated_data)
        return _response_data(NotificationPreferenceSerializer(pref).data)


class DeviceTokenView(APIView):
    permission_classes = [ActiveUserPermission]

    def post(self, request):
        serializer = DeviceTokenSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        DeviceTokenService.register(
            request.user,
            serializer.validated_data["token"],
            serializer.validated_data["device_type"],
        )
        return _response_data({"registered": True}, status_code=status.HTTP_201_CREATED)

    def delete(self, request):
        serializer = DeviceTokenRemoveSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        DeviceTokenService.remove(request.user, serializer.validated_data["token"])
        return Response(status=status.HTTP_204_NO_CONTENT)
