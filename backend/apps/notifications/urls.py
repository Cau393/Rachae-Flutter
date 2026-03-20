from django.urls import path

from apps.notifications.views import (
    DeviceTokenView,
    NotificationListView,
    NotificationMarkAllReadView,
    NotificationMarkReadView,
    NotificationPreferenceView,
)

urlpatterns = [
    path("", NotificationListView.as_view()),
    path("read-all/", NotificationMarkAllReadView.as_view()),
    path("preferences/", NotificationPreferenceView.as_view()),
    path("<uuid:notification_id>/read/", NotificationMarkReadView.as_view()),
    path("device-token/", DeviceTokenView.as_view()),
]
