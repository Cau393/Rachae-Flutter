import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';

/// Invalidated after group create/delete (see notifiers).
final groupListProvider =
    FutureProvider.autoDispose<List<GroupSummaryModel>>(
  (ref) => ref.watch(groupRepositoryProvider).fetchGroups(),
  retry: (int retryCount, Object error) => null,
);
