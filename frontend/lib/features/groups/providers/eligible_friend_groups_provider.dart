import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';

final eligibleFriendGroupsProvider = FutureProvider.autoDispose
    .family<List<GroupSummaryModel>, String>(
      (ref, friendId) => ref
          .watch(groupRepositoryProvider)
          .fetchEligibleGroupsForFriend(friendId),
      retry: (int retryCount, Object error) => null,
    );
