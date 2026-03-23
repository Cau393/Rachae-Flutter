from django.urls import path

from apps.users.views import (
    AvatarConfirmView,
    AvatarUploadUrlView,
    CurrentUserView,
    FriendInviteAcceptView,
    FriendInviteView,
    FriendListView,
    UserBalanceView,
    UserPairwiseBalancesView,
    UserSearchView,
)

urlpatterns = [
    path("users/me/pairwise-balances/", UserPairwiseBalancesView.as_view(), name="users-me-pairwise-balances"),
    path("users/me/", CurrentUserView.as_view(), name="users-me"),
    path("users/search/", UserSearchView.as_view(), name="users-search"),
    path("users/friends/", FriendListView.as_view(), name="users-friends"),
    path("users/friends/invite/", FriendInviteView.as_view(), name="users-friends-invite"),
    path("users/friends/accept/", FriendInviteAcceptView.as_view(), name="users-friends-accept"),
    path("users/<uuid:user_id>/balances/", UserBalanceView.as_view(), name="users-balances"),
    path("users/me/avatar-upload-url/", AvatarUploadUrlView.as_view(), name="users-avatar-upload-url"),
    path("users/me/avatar-confirm/", AvatarConfirmView.as_view(), name="users-avatar-confirm"),
]
