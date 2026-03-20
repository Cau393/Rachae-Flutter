from django.urls import path

from apps.groups import views

urlpatterns = [
    path("groups/", views.GroupListCreateView.as_view(), name="groups-list-create"),
    path("groups/<uuid:group_id>/", views.GroupDetailView.as_view(), name="groups-detail"),
    path("groups/<uuid:group_id>/members/", views.GroupMemberListView.as_view(), name="groups-members"),
    path(
        "groups/<uuid:group_id>/members/<uuid:user_id>/",
        views.GroupMemberDetailView.as_view(),
        name="groups-member-detail",
    ),
    path("groups/<uuid:group_id>/leave/", views.GroupLeaveView.as_view(), name="groups-leave"),
    path("groups/<uuid:group_id>/balances/", views.GroupBalancesView.as_view(), name="groups-balances"),
    path(
        "groups/<uuid:group_id>/balances/simplified/",
        views.GroupSimplifiedBalancesView.as_view(),
        name="groups-balances-simplified",
    ),
    path("groups/<uuid:group_id>/report/", views.GroupReportView.as_view(), name="groups-report"),
]
