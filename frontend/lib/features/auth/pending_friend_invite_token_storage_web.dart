// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

const _storageKey = 'pending_friend_invite_token';

void persistPendingFriendInviteToken(String? token) {
  final normalized = token?.trim();
  if (normalized == null || normalized.isEmpty) {
    html.window.sessionStorage.remove(_storageKey);
    return;
  }
  html.window.sessionStorage[_storageKey] = normalized;
}

String? readPendingFriendInviteToken() {
  final token = html.window.sessionStorage[_storageKey]?.trim();
  if (token == null || token.isEmpty) {
    return null;
  }
  return token;
}

void clearPendingFriendInviteTokenStorage() {
  html.window.sessionStorage.remove(_storageKey);
}
