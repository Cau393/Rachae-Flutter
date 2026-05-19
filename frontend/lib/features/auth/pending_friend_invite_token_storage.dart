import 'pending_friend_invite_token_storage_stub.dart'
    if (dart.library.html) 'pending_friend_invite_token_storage_web.dart'
    as impl;

void persistPendingFriendInviteToken(String? token) {
  impl.persistPendingFriendInviteToken(token);
}

String? readPendingFriendInviteToken() {
  return impl.readPendingFriendInviteToken();
}

void clearPendingFriendInviteTokenStorage() {
  impl.clearPendingFriendInviteTokenStorage();
}
