import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';

final friendInviteNotifierProvider =
    AsyncNotifierProvider.autoDispose<FriendInviteNotifier, void>(
  FriendInviteNotifier.new,
);

class FriendInviteNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> sendInvite() async {
    state = const AsyncLoading<void>();
    try {
      final invite = await ref.read(friendsRepositoryProvider).createInvite();
      await Clipboard.setData(ClipboardData(text: invite.inviteUrl));
      state = const AsyncData<void>(null);
      ref.invalidate(friendsProvider);
    } catch (e, s) {
      state = AsyncError<void>(e, s);
    }
  }
}
