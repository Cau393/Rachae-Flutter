import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';

/// Separate from detail so membership mutations can invalidate alone.
final groupMembersProvider =
    FutureProvider.autoDispose.family<List<GroupMemberModel>, String>(
  (ref, groupId) =>
      ref.watch(groupRepositoryProvider).fetchGroupMembers(groupId),
  retry: (int retryCount, Object error) => null,
);

/// Friends of the current user who are not members of [groupId] (by `user_id`).
final friendsNotInGroupProvider =
    FutureProvider.autoDispose.family<List<FriendModel>, String>(
  (ref, groupId) async {
    final friends = await ref.watch(friendsProvider.future);
    final members = await ref.watch(groupMembersProvider(groupId).future);
    final memberIds = members.map((m) => m.userId).toSet();
    final eligible =
        friends.where((f) => !memberIds.contains(f.id)).toList(growable: false);
    eligible.sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
    return eligible;
  },
  retry: (int retryCount, Object error) => null,
);
