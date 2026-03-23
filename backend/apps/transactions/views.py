from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import PermissionDenied, ValidationError
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.transactions.filters import TransactionFilter
from apps.transactions.models import Transaction
from apps.transactions.proof_service import TransactionProofService
from apps.transactions.serializers import (
    ProofFileKeySerializer,
    ProofUploadURLQuerySerializer,
    TransactionCreateSerializer,
    TransactionOutputSerializer,
)
from apps.transactions.services import TransactionService
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

        try:
            transaction = TransactionService.create(request.user, serializer.validated_data)
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(
            TransactionOutputSerializer(transaction).data,
            status_code=status.HTTP_201_CREATED,
        )


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
        transaction = get_object_or_404(Transaction, id=transaction_id)

        try:
            transaction = TransactionService.confirm(transaction, request.user)
        except PermissionDenied:
            raise
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(TransactionOutputSerializer(transaction).data)


class TransactionDisputeView(TransactionBaseView):
    def patch(self, request, transaction_id):
        transaction = get_object_or_404(Transaction, id=transaction_id)

        try:
            transaction = TransactionService.dispute(transaction, request.user)
        except PermissionDenied:
            raise
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc

        return _response_data(TransactionOutputSerializer(transaction).data)
