from django.urls import path

from apps.expenses.views import (
    ExpenseBatchUpdateView,
    ExpenseDetailView,
    ExpenseListCreateView,
    ExpenseReceiptConfirmView,
    ExpenseReceiptDeleteView,
    ExpenseReceiptUploadURLView,
    ExpenseRestoreView,
)

urlpatterns = [
    path("expenses/", ExpenseListCreateView.as_view(), name="expenses-list-create"),
    path("expenses/batch/", ExpenseBatchUpdateView.as_view(), name="expenses-batch"),
    path("expenses/<uuid:expense_id>/", ExpenseDetailView.as_view(), name="expenses-detail"),
    path(
        "expenses/<uuid:expense_id>/restore/",
        ExpenseRestoreView.as_view(),
        name="expenses-restore",
    ),
    path(
        "expenses/<uuid:expense_id>/receipt-upload-url/",
        ExpenseReceiptUploadURLView.as_view(),
        name="expenses-receipt-upload-url",
    ),
    path(
        "expenses/<uuid:expense_id>/receipts/confirm/",
        ExpenseReceiptConfirmView.as_view(),
        name="expenses-receipt-confirm",
    ),
    path(
        "expenses/<uuid:expense_id>/receipts/",
        ExpenseReceiptDeleteView.as_view(),
        name="expenses-receipt-delete",
    ),
]
