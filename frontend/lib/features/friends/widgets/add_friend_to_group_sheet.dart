import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/eligible_friend_groups_provider.dart';
import 'package:frontend/features/groups/providers/group_settings_notifier.dart';
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

  Future<void> _addToGroup(GroupSummaryModel group) async {
    setState(() {
      _submittingGroupId = group.id;
    });
    try {
      final messenger = ScaffoldMessenger.of(context);
      await ref
          .read(groupSettingsNotifierProvider(group.id).notifier)
          .addMember(widget.friendId, 'MEMBER');
      ref.invalidate(eligibleFriendGroupsProvider(widget.friendId));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(
              context,
            )!.friendDetailAddedToGroupSuccess(widget.friendName, group.name),
          ),
        ),
      );
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
            if (groups.isEmpty) {
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
                    itemCount: groups.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final group = groups[index];
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
