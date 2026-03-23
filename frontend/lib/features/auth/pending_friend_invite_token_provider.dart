import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists invite token from `/login?invite_token=` (or `/invite?`) until accept is done.
final pendingFriendInviteTokenProvider =
    NotifierProvider<PendingFriendInviteTokenNotifier, String?>(
  PendingFriendInviteTokenNotifier.new,
);

class PendingFriendInviteTokenNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setToken(String? value) => state = value;

  void clear() => state = null;
}
