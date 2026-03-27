import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart'
    show friendsNotInGroupProvider, groupMembersProvider;
import 'package:frontend/features/groups/providers/group_repository_provider.dart';

/// Optional snackbar after successful save — overridden at app level.
final groupSettingsOnSaveSuccessProvider = Provider<void Function()?>(
  (ref) => null,
);

/// Called after delete or leave to navigate away (e.g. `go('/groups')`).
final groupSettingsAfterLeaveProvider = Provider<void Function()>(
  (ref) => () {},
);

final groupSettingsNotifierProvider =
    AsyncNotifierProvider.autoDispose.family<GroupSettingsNotifier, void, String>(
  GroupSettingsNotifier.new,
);

/// Outcome of [GroupSettingsNotifier.addMembersBatch].
class AddMembersBatchResult {
  const AddMembersBatchResult({
    required this.addedCount,
    required this.failedUserIds,
  });

  final int addedCount;
  final List<String> failedUserIds;
}

class GroupSettingsNotifier extends AsyncNotifier<void> {
  GroupSettingsNotifier(this.groupId);

  final String groupId;

  @override
  Future<void> build() async {}

  Future<void> saveSettings(Map<String, dynamic> changed) async {
    state = const AsyncLoading<void>();
    try {
      await ref.read(groupRepositoryProvider).updateGroup(groupId, changed);
      ref.invalidate(groupDetailProvider(groupId));
      ref.read(groupSettingsOnSaveSuccessProvider)?.call();
      state = const AsyncData<void>(null);
    } catch (e, s) {
      state = AsyncError<void>(e, s);
    }
  }

  Future<void> deleteSelf() async {
    state = const AsyncLoading<void>();
    try {
      await ref.read(groupRepositoryProvider).deleteGroup(groupId);
      ref.invalidate(groupListProvider);
      ref.invalidate(groupDetailProvider(groupId));
      ref.read(groupSettingsAfterLeaveProvider)();
      state = const AsyncData<void>(null);
    } catch (e, s) {
      state = AsyncError<void>(e, s);
    }
  }

  Future<void> leaveGroup() async {
    state = const AsyncLoading<void>();
    try {
      await ref.read(groupRepositoryProvider).leaveGroup(groupId);
      ref.invalidate(groupListProvider);
      ref.invalidate(groupDetailProvider(groupId));
      ref.read(groupSettingsAfterLeaveProvider)();
      state = const AsyncData<void>(null);
    } catch (e, s) {
      state = AsyncError<void>(e, s);
    }
  }

  Future<void> addMember(String userId, String role) async {
    state = const AsyncLoading<void>();
    try {
      await ref
          .read(groupRepositoryProvider)
          .addMember(groupId, userId, role);
      ref.invalidate(groupMembersProvider(groupId));
      ref.invalidate(groupDetailProvider(groupId));
      ref.invalidate(friendsNotInGroupProvider(groupId));
      state = const AsyncData<void>(null);
    } catch (e, s) {
      state = AsyncError<void>(e, s);
    }
  }

  /// Adds each user as MEMBER; collects failures without aborting the rest.
  Future<AddMembersBatchResult> addMembersBatch(List<String> userIds) async {
    if (userIds.isEmpty) {
      return const AddMembersBatchResult(addedCount: 0, failedUserIds: []);
    }
    state = const AsyncLoading<void>();
    final repo = ref.read(groupRepositoryProvider);
    final failedUserIds = <String>[];
    var addedCount = 0;
    for (final id in userIds) {
      try {
        await repo.addMember(groupId, id, 'MEMBER');
        addedCount++;
      } catch (_) {
        failedUserIds.add(id);
      }
    }
    ref.invalidate(groupMembersProvider(groupId));
    ref.invalidate(groupDetailProvider(groupId));
    ref.invalidate(friendsNotInGroupProvider(groupId));
    ref.invalidate(groupListProvider);
    state = const AsyncData<void>(null);
    return AddMembersBatchResult(
      addedCount: addedCount,
      failedUserIds: failedUserIds,
    );
  }

  Future<void> changeMemberRole(String userId, String role) async {
    state = const AsyncLoading<void>();
    try {
      await ref
          .read(groupRepositoryProvider)
          .changeMemberRole(groupId, userId, role);
      ref.invalidate(groupMembersProvider(groupId));
      state = const AsyncData<void>(null);
    } catch (e, s) {
      state = AsyncError<void>(e, s);
    }
  }

  Future<void> removeMember(String userId) async {
    state = const AsyncLoading<void>();
    try {
      await ref.read(groupRepositoryProvider).removeMember(groupId, userId);
      ref.invalidate(groupMembersProvider(groupId));
      state = const AsyncData<void>(null);
    } catch (e, s) {
      state = AsyncError<void>(e, s);
    }
  }
}
