from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.exceptions import ValidationError
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.users.models import User
from apps.users.permissions import ActiveUserPermission
from apps.users.queries import search_users
from apps.users.serializers import (
    AvatarConfirmSerializer,
    AvatarUploadUrlRequestSerializer,
    AvatarUploadUrlResponseSerializer,
    BalanceSerializer,
    BalanceSummarySerializer,
    CurrentUserSerializer,
    PairwiseBalanceItemSerializer,
    CurrentUserUpdateSerializer,
    FriendInviteAcceptSerializer,
    FriendInviteCreateResponseSerializer,
    FriendInviteCreateSerializer,
    FriendInviteSerializer,
    FriendListSerializer,
    UserSearchQuerySerializer,
    UserSearchResultSerializer,
)
from apps.users.services import AvatarService, BalanceService, FriendService, InvitationService, UserService


class CurrentUserView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        serializer = CurrentUserSerializer(request.user)
        data = serializer.data
        data.update(BalanceSummarySerializer(BalanceService.get_balance_summary(request.user)).data)
        return Response(data)

    def patch(self, request):
        serializer = CurrentUserUpdateSerializer(request.user, data=request.data, partial=True)
        serializer.is_valid(raise_exception=True)
        user = UserService.update_profile(request.user, serializer.validated_data)
        data = CurrentUserSerializer(user).data
        data.update(BalanceSummarySerializer(BalanceService.get_balance_summary(user)).data)
        return Response(data)

    def delete(self, request):
        UserService.anonymize_and_soft_delete(request.user)
        return Response(status=status.HTTP_204_NO_CONTENT)


class UserSearchView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        query_serializer = UserSearchQuerySerializer(data=request.query_params)
        query_serializer.is_valid(raise_exception=True)
        users = search_users(query_serializer.validated_data["q"], request.user.id)
        return Response(UserSearchResultSerializer(users, many=True).data)


class FriendListView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        friends = FriendService.list_friends(request.user)
        return Response(FriendListSerializer(friends, many=True).data)


class FriendInviteView(APIView):
    permission_classes = [ActiveUserPermission]

    def post(self, request):
        serializer = FriendInviteCreateSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        data = serializer.validated_data
        try:
            payload = InvitationService.create_invite(
                request.user,
                email=data.get("email"),
                phone=data.get("phone"),
            )
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc
        return Response(FriendInviteCreateResponseSerializer(payload).data, status=status.HTTP_201_CREATED)


class FriendInviteAcceptView(APIView):
    permission_classes = [ActiveUserPermission]

    def post(self, request):
        serializer = FriendInviteAcceptSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            invite = InvitationService.accept_invite(request.user, serializer.validated_data["token"])
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc
        return Response(FriendInviteSerializer(invite).data)


class UserBalanceView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request, user_id):
        other_user = get_object_or_404(User, id=user_id)
        balance = BalanceService.get_pairwise_balance(request.user, other_user)
        return Response(BalanceSerializer(balance).data)


class UserPairwiseBalancesView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        rows = BalanceService.list_pairwise_nonzero(request.user)
        return Response(
            {
                "data": {
                    "balances": PairwiseBalanceItemSerializer(rows, many=True).data,
                }
            }
        )


class AvatarUploadUrlView(APIView):
    permission_classes = [ActiveUserPermission]

    def get(self, request):
        serializer = AvatarUploadUrlRequestSerializer(data=request.query_params)
        serializer.is_valid(raise_exception=True)
        payload = AvatarService.generate_avatar_upload(request.user, **serializer.validated_data)
        return Response(AvatarUploadUrlResponseSerializer(payload).data)


class AvatarConfirmView(APIView):
    permission_classes = [ActiveUserPermission]

    def patch(self, request):
        serializer = AvatarConfirmSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        try:
            user = AvatarService.confirm_avatar_upload(request.user, serializer.validated_data["file_key"])
        except ValueError as exc:
            raise ValidationError({"detail": str(exc)}) from exc
        return Response({"avatar_url": user.avatar_url})
