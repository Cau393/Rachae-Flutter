from django.urls import path

from apps.transactions.views import (
    TransactionConfirmView,
    TransactionDetailView,
    TransactionDisputeView,
    TransactionListCreateView,
)

urlpatterns = [
    path("transactions/", TransactionListCreateView.as_view()),
    path("transactions/<uuid:transaction_id>/", TransactionDetailView.as_view()),
    path("transactions/<uuid:transaction_id>/confirm/", TransactionConfirmView.as_view()),
    path("transactions/<uuid:transaction_id>/dispute/", TransactionDisputeView.as_view()),
]
