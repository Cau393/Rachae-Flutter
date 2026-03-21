from django.contrib import admin
from django.urls import include, path

API_V1_PREFIX = "api/v1/"

urlpatterns = [
    path("admin/", admin.site.urls),
    path(API_V1_PREFIX, include("core.urls")),
    path(API_V1_PREFIX, include("apps.groups.urls")),
    path(API_V1_PREFIX, include("apps.users.urls")),
    path(API_V1_PREFIX, include("apps.expenses.urls")),
    path(API_V1_PREFIX, include("apps.transactions.urls")),
    path(API_V1_PREFIX, include("apps.ledger.urls")),
    path(API_V1_PREFIX, include("apps.currencies.urls")),
    path(API_V1_PREFIX, include("apps.ads.urls")),
    path(f"{API_V1_PREFIX}notifications/", include("apps.notifications.urls")),
]
