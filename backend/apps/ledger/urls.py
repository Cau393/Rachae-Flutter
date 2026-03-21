from django.urls import path

from apps.ledger.views import (
    GroupActivityView,
    GroupBalancesView,
    GroupSimplifiedBalancesView,
    LedgerActivityView,
)

urlpatterns = [
    path("ledger/activity/", LedgerActivityView.as_view(), name="ledger-activity"),
    path("groups/<uuid:group_id>/balances/", GroupBalancesView.as_view(), name="groups-balances"),
    path(
        "groups/<uuid:group_id>/balances/simplified/",
        GroupSimplifiedBalancesView.as_view(),
        name="groups-balances-simplified",
    ),
    path("groups/<uuid:group_id>/activity/", GroupActivityView.as_view(), name="groups-activity"),
]
