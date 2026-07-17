from django.db.models import Q
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.groups.models import Group, GroupMember
from apps.transactions.filters import TransactionFilter
from apps.transactions.models import Transaction
from apps.transactions.proof_service import TransactionProofService
from apps.transactions.serializers import (
    OffsetCreditPreviewQuerySerializer,
    OffsetCreditPreviewResponseSerializer,
    ProofFileKeySerializer,
    ProofUploadURLQuerySerializer,
    TransactionCreateSerializer,
    TransactionOutputSerializer,
)
from apps.transactions.services import TransactionService
from apps.users.models import User
from apps.users.permissions import ActiveUserPermission


def _response_data(payload, *, status_code=status.HTTP_200_OK):
    return Response({"data": payload}, status=status_code)


class TransactionPagination(PageNumberPagination):
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


class TransactionBaseView(APIView):
    permission_classes = [ActiveUserPermission]


class TransactionListCreateView(TransactionBaseView):
    def get(self, request):
        filterset = TransactionFilter(data=request.query_params)
        if not filterset.is_valid():
            raise ValidationError(filterset.errors)

        queryset = TransactionService.list(request.user, filterset.form.cleaned_data)
        paginator = TransactionPagination()
        page = paginator.paginate_queryset(queryset, request)

        return paginator.get_paginated_response(
            TransactionOutputSerializer(page, many=True).data
        )

    def post(self, request):
        serializer = TransactionCreateSerializer(
            data=request.data,
            context={"request": request},
        )
        serializer.is_valid(raise_exception=True)

        payload = dict(serializer.validated_data)
        is_offset = payload.pop("is_offset", False)
        try:
            if is_offset:
                transactions = TransactionService.create_offset(request.user, payload)
            else:
                transactions = TransactionService.create(request.user, payload)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(
            TransactionOutputSerializer(
                transactions,
                many=True,
            ).data,
            status_code=status.HTTP_201_CREATED,
        )


class TransactionOffsetCreditPreviewView(TransactionBaseView):
    def get(self, request):
        query_serializer = OffsetCreditPreviewQuerySerializer(data=request.query_params)
        query_serializer.is_valid(raise_exception=True)
        with_user_id = query_serializer.validated_data["with_user"]
        exclude_group_id = query_serializer.validated_data["exclude_group"]

        if with_user_id == request.user.id:
            raise ValidationError({"with_user": "Cannot query offset credit with yourself."})

        other_user = get_object_or_404(User, id=with_user_id)
        group = get_object_or_404(Group, id=exclude_group_id, is_deleted=False)

        if not GroupMember.objects.filter(
            group=group,
            user=request.user,
            is_deleted=False,
        ).exists():
            raise ValidationError({"exclude_group": "You are not a member of this group."})

        if not GroupMember.objects.filter(
            group=group,
            user=other_user,
            is_deleted=False,
        ).exists():
            raise ValidationError(
                {"exclude_group": "Counterparty is not a member of this group."}
            )

        raw = TransactionService.offset_credit_excluding_group(
            request.user, other_user, exclude_group_id
        )
        out = OffsetCreditPreviewResponseSerializer(raw).data
        return _response_data(out)


class TransactionDetailView(TransactionBaseView):
    def get(self, request, transaction_id):
        transaction = TransactionService.get(str(transaction_id), request.user)
        return _response_data(TransactionOutputSerializer(transaction).data)


class TransactionProofUploadURLView(TransactionBaseView):
    def get(self, request, transaction_id):
        transaction = TransactionService.get(str(transaction_id), request.user)

        serializer = ProofUploadURLQuerySerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)

        payload = TransactionProofService.generate_upload_url(
            transaction,
            request.user,
            content_type=serializer.validated_data["content_type"],
        )

        return _response_data(payload)


class TransactionProofConfirmView(TransactionBaseView):
    def patch(self, request, transaction_id):
        transaction = TransactionService.get(str(transaction_id), request.user)

        serializer = ProofFileKeySerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        transaction = TransactionProofService.confirm_upload(
            transaction,
            serializer.validated_data["file_key"],
            request.user,
        )

        return _response_data(TransactionOutputSerializer(transaction).data)


class TransactionConfirmView(TransactionBaseView):
    def patch(self, request, transaction_id):
        # Scope the fetch to transactions the caller is party to (payer or
        # receiver) so a stranger's pk gets a 404, not a fetch-then-403.
        # TransactionService.confirm still enforces receiver-only below.
        transaction = get_object_or_404(
            Transaction.objects.filter(Q(payer=request.user) | Q(receiver=request.user)),
            id=transaction_id,
        )

        try:
            transaction = TransactionService.confirm(transaction, request.user)
        except PermissionDenied:
            raise
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(TransactionOutputSerializer(transaction).data)


class TransactionDisputeView(TransactionBaseView):
    def patch(self, request, transaction_id):
        # Same scoping as TransactionConfirmView — see comment there.
        transaction = get_object_or_404(
            Transaction.objects.filter(Q(payer=request.user) | Q(receiver=request.user)),
            id=transaction_id,
        )

        try:
            transaction = TransactionService.dispute(transaction, request.user)
        except PermissionDenied:
            raise
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(TransactionOutputSerializer(transaction).data)
