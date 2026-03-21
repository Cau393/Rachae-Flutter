import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';

/// Separate from detail so membership mutations can invalidate alone.
final groupMembersProvider =
    FutureProvider.autoDispose.family<List<GroupMemberModel>, String>(
  (ref, groupId) =>
      ref.watch(groupRepositoryProvider).fetchGroupMembers(groupId),
  retry: (int retryCount, Object error) => null,
);
