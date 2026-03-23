import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';

/// Invalidated after a successful friend invite (see [FriendInviteNotifier]).
final friendsProvider = FutureProvider.autoDispose<List<FriendModel>>(
  (ref) => ref.watch(friendsRepositoryProvider).fetchFriends(),
  retry: (int retryCount, Object error) => null,
);
