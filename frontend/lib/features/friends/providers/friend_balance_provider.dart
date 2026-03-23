import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/friends/models/friend_balance_model.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';

/// Invalidated after a transaction is confirmed or after recording settlement
/// (see [SettleUpNotifier]).
final friendBalanceProvider =
    FutureProvider.autoDispose.family<FriendBalanceModel, String>(
  (ref, userId) =>
      ref.watch(friendsRepositoryProvider).fetchFriendBalance(userId),
  retry: (int retryCount, Object error) => null,
);
