from django.db.models import Exists, OuterRef, Q
from django.http import Http404
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.expenses.filters import ExpenseFilter
from apps.expenses.models import Expense
from apps.expenses.permissions import IsCreatorOrGroupAdmin, _get_group_membership
from apps.expenses.serializers import (
    BatchUpdateSerializer,
    ExpenseCreateSerializer,
    ExpenseDetailSerializer,
    ExpenseListSerializer,
    ExpensePartialUpdateSerializer,
    ExpenseUpdateSerializer,
    ReceiptFileKeySerializer,
    ReceiptUploadURLQuerySerializer,
)
from apps.expenses.services import ExpenseService, ReceiptService
from apps.groups.models import GroupMember, GroupRole
from apps.splits.models import Split
from apps.users.permissions import ActiveUserPermission
def _response_data(payload, *, status_code=status.HTTP_200_OK):
    return Response({"data": payload}, status=status_code)


def _expense_detail_payload(expense):
    serializer = ExpenseDetailSerializer(expense)
    return serializer.data


class ExpensePagination(PageNumberPagination):
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


class ExpenseBaseView(APIView):
    permission_classes = [ActiveUserPermission]

    def get_expense(self, expense_id, *, include_deleted=False):
        manager = Expense.all_objects if include_deleted else Expense.objects
        user = self.request.user
        is_group_member = GroupMember.objects.filter(
            group_id=OuterRef("group_id"), user=user, is_deleted=False
        )
        is_own_split = Split.objects.filter(
            expense_id=OuterRef("pk"), user=user, is_deleted=False
        )
        # Mirrors ExpenseService._is_user_involved exactly: group membership
        # grants access to group expenses, but payer/creator/split
        # participant grant access regardless of group — a user who created
        # or paid a group expense and later left the group must still be
        # able to reach it. Folds authZ into the fetch so a stranger's pk
        # 404s instead of fetch-then-403 — per-action checks
        # (require_object_permission / require_group_admin) still apply on
        # top for write operations.
        involved = (
            (Q(group_id__isnull=False) & Exists(is_group_member))
            | Q(paid_by=user)
            | Q(created_by=user)
            | Exists(is_own_split)
        )
        return get_object_or_404(
            manager.select_related("paid_by", "created_by", "group")
            .prefetch_related("splits__user")
            .filter(involved),
            id=expense_id,
        )

    def require_object_permission(self, request, expense, permission_class):
        permission = permission_class()
        if not permission.has_object_permission(request, self, expense):
            raise PermissionDenied(getattr(permission, "message", None))

    def require_group_admin(self, request, expense):
        membership = _get_group_membership(request.user, expense.group_id)
        if not membership or membership.role != GroupRole.ADMIN:
            raise PermissionDenied("You must be an admin of this expense group.")


class ExpenseListCreateView(ExpenseBaseView):
    def get(self, request):
        filterset = ExpenseFilter(data=request.query_params)
        if not filterset.is_valid():
            raise ValidationError(filterset.errors)

        queryset = ExpenseService.list(request.user, filterset.form.cleaned_data)
        paginator = ExpensePagination()
        page = paginator.paginate_queryset(queryset, request)

        return paginator.get_paginated_response(
            ExpenseListSerializer(page, many=True).data
        )

    def post(self, request):
        serializer = ExpenseCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            expense = ExpenseService.create(request.user, serializer.validated_data)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        expense = self.get_expense(expense.id)
        return _response_data(
            ExpenseDetailSerializer(expense).data,
            status_code=status.HTTP_201_CREATED,
        )


class ExpenseDetailView(ExpenseBaseView):
    def get(self, request, expense_id):
        expense = ExpenseService.get(expense_id, request.user)
        return _response_data(_expense_detail_payload(expense))

    def put(self, request, expense_id):
        expense = self.get_expense(expense_id)
        self.require_object_permission(request, expense, IsCreatorOrGroupAdmin)

        serializer = ExpenseUpdateSerializer(
            data=request.data,
            context={"expense": expense},
        )
        serializer.is_valid(raise_exception=True)

        try:
            expense = ExpenseService.full_update(expense, serializer.validated_data, request.user)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(ExpenseDetailSerializer(expense).data)

    def patch(self, request, expense_id):
        expense = self.get_expense(expense_id)
        self.require_object_permission(request, expense, IsCreatorOrGroupAdmin)

        serializer = ExpensePartialUpdateSerializer(data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        expense = ExpenseService.partial_update(expense, serializer.validated_data, request.user)

        return _response_data(ExpenseDetailSerializer(expense).data)

    def delete(self, request, expense_id):
        expense = self.get_expense(expense_id)
        self.require_object_permission(request, expense, IsCreatorOrGroupAdmin)

        ExpenseService.soft_delete(expense, request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class ExpenseBatchUpdateView(ExpenseBaseView):
    def put(self, request):
        serializer = BatchUpdateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        allowed_updates = []
        precheck_errors = []

        for item in serializer.validated_data["updates"]:
            try:
                expense = self.get_expense(item["id"])
            except Http404:
                precheck_errors.append({"id": str(item["id"]), "error": "Not found"})
                continue

            try:
                self.require_group_admin(request, expense)
            except PermissionDenied as exc:
                precheck_errors.append({"id": str(item["id"]), "error": str(exc.detail)})
                continue

            allowed_updates.append(item)

        result = ExpenseService.batch_update(allowed_updates, request.user)
        result["errors"] = precheck_errors + result["errors"]

        return _response_data(result)


class ExpenseRestoreView(ExpenseBaseView):
    def post(self, request, expense_id):
        expense = self.get_expense(expense_id, include_deleted=True)
        if not expense.is_deleted:
            raise ValidationError({"detail": "Expense is not deleted."})

        self.require_group_admin(request, expense)
        expense = ExpenseService.restore(expense, request.user)

        return _response_data(_expense_detail_payload(expense))


class ExpenseReceiptUploadURLView(ExpenseBaseView):
    def get(self, request, expense_id):
        expense = self.get_expense(expense_id)
        self.require_object_permission(request, expense, IsCreatorOrGroupAdmin)

        serializer = ReceiptUploadURLQuerySerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)
        payload = ReceiptService.generate_upload_url(
            expense,
            request.user,
            content_type=serializer.validated_data["content_type"],
        )

        return _response_data(payload)


class ExpenseReceiptConfirmView(ExpenseBaseView):
    def patch(self, request, expense_id):
        expense = self.get_expense(expense_id)
        self.require_object_permission(request, expense, IsCreatorOrGroupAdmin)

        serializer = ReceiptFileKeySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            expense = ReceiptService.confirm_upload(
                expense,
                serializer.validated_data["file_key"],
                request.user,
            )
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(_expense_detail_payload(expense))


class ExpenseReceiptDeleteView(ExpenseBaseView):
    def delete(self, request, expense_id):
        expense = self.get_expense(expense_id)
        self.require_object_permission(request, expense, IsCreatorOrGroupAdmin)

        serializer = ReceiptFileKeySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            ReceiptService.remove_receipt(
                expense,
                serializer.validated_data["file_key"],
                request.user,
            )
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return Response(status=status.HTTP_204_NO_CONTENT)
