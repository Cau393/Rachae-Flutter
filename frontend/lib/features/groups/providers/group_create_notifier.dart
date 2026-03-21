import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';

/// Overridden in tests / app to navigate to `/groups/{id}` after create.
final groupCreateOnSuccessProvider =
    Provider<void Function(String newGroupId)>((ref) => (_) {});

final groupCreateNotifierProvider =
    AsyncNotifierProvider.autoDispose<GroupCreateNotifier, void>(
  GroupCreateNotifier.new,
);

class GroupCreateNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  /// Returns the new group id on success, or `null` when [state] is [AsyncError].
  Future<String?> submit(Map<String, dynamic> fields) async {
    state = const AsyncLoading<void>();
    try {
      final detail =
          await ref.read(groupRepositoryProvider).createGroup(fields);
      ref.invalidate(groupListProvider);
      ref.read(groupCreateOnSuccessProvider)(detail.id);
      state = const AsyncData<void>(null);
      return detail.id;
    } catch (e, s) {
      state = AsyncError<void>(e, s);
      return null;
    }
  }
}
