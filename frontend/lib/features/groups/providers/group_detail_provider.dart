import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';

/// Invalidated after settings save / delete / leave as appropriate.
final groupDetailProvider =
    FutureProvider.autoDispose.family<GroupDetailModel, String>(
  (ref, groupId) =>
      ref.watch(groupRepositoryProvider).fetchGroupDetail(groupId),
  retry: (int retryCount, Object error) => null,
);
