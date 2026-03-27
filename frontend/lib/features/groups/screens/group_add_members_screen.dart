import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart';
import 'package:frontend/features/groups/providers/group_settings_notifier.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class GroupAddMembersScreen extends ConsumerStatefulWidget {
  const GroupAddMembersScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupAddMembersScreen> createState() =>
      _GroupAddMembersScreenState();
}

class _GroupAddMembersScreenState extends ConsumerState<GroupAddMembersScreen> {
  String _searchQuery = '';
  final Set<String> _selectedIds = <String>{};
  bool _submitting = false;

  List<FriendModel> _filtered(List<FriendModel> eligible) {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) {
      return eligible;
    }
    return eligible
        .where(
          (f) =>
              f.displayName.toLowerCase().contains(q) ||
              f.email.toLowerCase().contains(q),
        )
        .toList();
  }

  String _currentUserIdForGroup() {
    final djangoId = ref.read(profileNotifierProvider).maybeWhen(
          data: (p) => p.id,
          orElse: () => '',
        );
    if (djangoId.isNotEmpty) return djangoId;
    return ref.read(authNotifierProvider).maybeWhen(
          data: (s) => switch (s) {
            AuthStateAuthenticated(:final user) => user.id,
            _ => '',
          },
          orElse: () => '',
        );
  }

  Future<void> _onRefresh() async {
    ref.invalidate(friendsProvider);
    ref.invalidate(groupMembersProvider(widget.groupId));
    ref.invalidate(friendsNotInGroupProvider(widget.groupId));
    await Future.wait([
      ref.read(friendsProvider.future),
      ref.read(friendsNotInGroupProvider(widget.groupId).future),
    ]);
    if (mounted) setState(() {});
  }

  Future<void> _onConfirm() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.groupAddMembersSelectAtLeastOne)),
      );
      return;
    }
    final idsToAdd = _selectedIds.toList(growable: false);
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(groupSettingsNotifierProvider(widget.groupId).notifier)
          .addMembersBatch(idsToAdd);
      if (!mounted) return;
      setState(() {
        _selectedIds
          ..clear()
          ..addAll(result.failedUserIds);
      });
      if (result.addedCount > 0 && result.failedUserIds.isEmpty) {
        context.pop<int>(result.addedCount);
        return;
      } else if (result.failedUserIds.isNotEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              l10n.groupAddMembersPartialFailure(
                result.failedUserIds.length,
                idsToAdd.length,
              ),
            ),
          ),
        );
      }
      if (result.addedCount > 0) {
        ref.invalidate(friendsNotInGroupProvider(widget.groupId));
        ref.invalidate(groupMembersProvider(widget.groupId));
        ref.invalidate(groupDetailProvider(widget.groupId));
        ref.invalidate(groupListProvider);
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(l10n.errorGeneric)));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Subscribes so AsyncNotifierProvider.autoDispose is not disposed mid-await
    // during addMembersBatch (see Riverpod UnmountedRefException on ref.invalidate).
    ref.watch(groupSettingsNotifierProvider(widget.groupId));

    ref.listen<AsyncValue<GroupDetailModel>>(
      groupDetailProvider(widget.groupId),
      (previous, next) {
        next.whenData((detail) {
          final uid = _currentUserIdForGroup();
          if (uid.isEmpty) return;
          final role = detail.memberByUserId(uid)?.role ?? 'VIEWER';
          if (role != 'ADMIN' && context.mounted) {
            context.go('/groups/${widget.groupId}');
          }
        });
      },
    );

    final friendsAsync = ref.watch(friendsProvider);
    final eligibleAsync = ref.watch(friendsNotInGroupProvider(widget.groupId));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.groupAddMembersTitle),
      ),
      body: friendsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.errorGeneric),
              TextButton(
                onPressed: () => ref.invalidate(friendsProvider),
                child: Text(l10n.retryLabel),
              ),
            ],
          ),
        ),
        data: (allFriends) {
          if (allFriends.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.groupAddMembersNoFriends,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return eligibleAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.errorGeneric),
                  TextButton(
                    onPressed: () => ref.invalidate(
                      friendsNotInGroupProvider(widget.groupId),
                    ),
                    child: Text(l10n.retryLabel),
                  ),
                ],
              ),
            ),
            data: (eligible) {
              if (eligible.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      l10n.groupAddMembersAllInGroup,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                );
              }
              final filtered = _filtered(eligible);
              final canSubmit = _selectedIds.isNotEmpty && !_submitting;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                    child: SearchBar(
                      hintText: l10n.friendsSearchHint,
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _onRefresh,
                      child: filtered.isEmpty
                          ? ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.sizeOf(context).height * 0.3,
                                ),
                                Center(child: Text(l10n.noResultsLabel)),
                              ],
                            )
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: filtered.length,
                              itemBuilder: (context, i) {
                                final f = filtered[i];
                                final selected = _selectedIds.contains(f.id);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: _submitting
                                      ? null
                                      : (v) {
                                          setState(() {
                                            if (v ?? false) {
                                              _selectedIds.add(f.id);
                                            } else {
                                              _selectedIds.remove(f.id);
                                            }
                                          });
                                        },
                                  secondary: CircleAvatar(
                                    child: Text(
                                      f.displayName.isNotEmpty
                                          ? f.displayName[0].toUpperCase()
                                          : '?',
                                    ),
                                  ),
                                  title: Text(f.displayName),
                                  subtitle: Text(
                                    f.email,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                );
                              },
                            ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: !canSubmit
                              ? null
                              : _onConfirm,
                          child: _submitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _selectedIds.isEmpty
                                      ? l10n.groupAddMembersConfirmButton
                                      : l10n.groupAddMembersConfirmWithCount(
                                          _selectedIds.length,
                                        ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
