import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/eligible_friend_groups_provider.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart'
    show friendsNotInGroupProvider, groupMembersProvider;
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class AddFriendToGroupSheet extends ConsumerStatefulWidget {
  const AddFriendToGroupSheet({
    super.key,
    required this.friendId,
    required this.friendName,
  });

  final String friendId;
  final String friendName;

  @override
  ConsumerState<AddFriendToGroupSheet> createState() =>
      _AddFriendToGroupSheetState();
}

class _AddFriendToGroupSheetState extends ConsumerState<AddFriendToGroupSheet> {
  String? _submittingGroupId;

  /// Groups hidden immediately after a successful add (before eligible list refetch).
  final Set<String> _removedGroupIds = <String>{};

  List<GroupSummaryModel> _visibleGroups(List<GroupSummaryModel> serverGroups) {
    return serverGroups
        .where((g) => !_removedGroupIds.contains(g.id))
        .toList();
  }

  Future<void> _addToGroup(GroupSummaryModel group) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _submittingGroupId = group.id;
    });
    try {
      await ref.read(groupRepositoryProvider).addMember(
        group.id,
        widget.friendId,
        'MEMBER',
      );
      ref.invalidate(groupMembersProvider(group.id));
      ref.invalidate(groupDetailProvider(group.id));
      ref.invalidate(friendsNotInGroupProvider(group.id));
      if (mounted) {
        setState(() {
          _removedGroupIds.add(group.id);
        });
      }
      ref.invalidate(eligibleFriendGroupsProvider(widget.friendId));
      try {
        await ref.read(eligibleFriendGroupsProvider(widget.friendId).future);
        if (mounted) {
          final async = ref.read(eligibleFriendGroupsProvider(widget.friendId));
          if (async.hasValue) {
            final ids = async.value!.map((g) => g.id).toSet();
            setState(() {
              _removedGroupIds.removeWhere((id) => !ids.contains(id));
            });
          }
        }
      } catch (_) {
        // List refresh failed; optimistic row stays hidden; Retry refetches.
      }
      if (!mounted) {
        return;
      }
      if (messenger != null && l10n != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.friendDetailAddedToGroupSuccess(
                widget.friendName,
                group.name,
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submittingGroupId = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final eligibleGroupsAsync = ref.watch(
      eligibleFriendGroupsProvider(widget.friendId),
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: eligibleGroupsAsync.when(
          loading: () => const SizedBox(
            height: 200,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.errorGeneric),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(
                      eligibleFriendGroupsProvider(widget.friendId),
                    ),
                    child: Text(l10n.retryLabel),
                  ),
                ],
              ),
            ),
          ),
          data: (groups) {
            final visible = _visibleGroups(groups);
            if (visible.isEmpty) {
              return SizedBox(
                height: 160,
                child: Center(
                  child: Text(
                    l10n.friendDetailNoEligibleGroups,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.friendDetailAddToGroupButton,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final group = visible[index];
                      final isSubmitting = _submittingGroupId == group.id;
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(group.name),
                        subtitle: Text(group.currency),
                        trailing: FilledButton(
                          onPressed: isSubmitting
                              ? null
                              : () => _addToGroup(group),
                          child: isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(l10n.saveLabel),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
