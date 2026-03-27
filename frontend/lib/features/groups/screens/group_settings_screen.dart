import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart';
import 'package:frontend/features/groups/providers/group_settings_notifier.dart';
import 'package:frontend/features/groups/widgets/currency_dropdown.dart';
import 'package:frontend/features/groups/widgets/group_type_selector.dart';
import 'package:frontend/features/groups/widgets/member_list_tile.dart';
import 'package:frontend/features/groups/widgets/simplify_debts_toggle.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  const GroupSettingsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupSettingsScreen> createState() =>
      _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  final _nameController = TextEditingController();
  bool _seeded = false;
  String _type = 'home';
  String _currency = 'BRL'; // ignore: hardcoded — seed until detail loads (ISO 4217 MVP default)
  bool _simplifyDebts = false;

  @override
  void didUpdateWidget(GroupSettingsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId) {
      _seeded = false;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _currentUserId(AsyncValue<AuthState> auth) {
    return switch (auth.value) {
      AuthStateAuthenticated(:final user) => user.id,
      _ => '',
    };
  }

  bool _isLastAdmin(GroupDetailModel detail, String userId) {
    if (userId.isEmpty) return false;
    final me = detail.memberByUserId(userId);
    if (me?.role != 'ADMIN') return false;
    final adminCount = detail.members.where((m) => m.role == 'ADMIN').length;
    return adminCount == 1;
  }

  Map<String, dynamic> _changedFields(GroupDetailModel detail) {
    final m = <String, dynamic>{};
    if (_nameController.text != detail.name) {
      m['name'] = _nameController.text;
    }
    if (_type != detail.type) {
      m['type'] = _type;
    }
    if (_currency != detail.currency) {
      m['currency'] = _currency;
    }
    if (_simplifyDebts != detail.simplifyDebts) {
      m['simplify_debts'] = _simplifyDebts;
    }
    return m;
  }

  Future<void> _onSave(AppLocalizations l10n, GroupDetailModel detail) async {
    final changed = _changedFields(detail);
    if (changed.isEmpty) return;

    await ref
        .read(groupSettingsNotifierProvider(widget.groupId).notifier)
        .saveSettings(changed);

    if (!mounted) return;

    final async = ref.read(groupSettingsNotifierProvider(widget.groupId));
    async.whenOrNull(
      data: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.groupSettingsSaveSuccess)),
        );
      },
    );
  }

  Future<void> _confirmDelete(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.groupSettingsDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref
        .read(groupSettingsNotifierProvider(widget.groupId).notifier)
        .deleteSelf();

    if (!mounted) return;
    context.go('/groups');
    ref.invalidate(groupListProvider);
  }

  Future<void> _confirmLeave(AppLocalizations l10n) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.groupSettingsLeaveConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref
        .read(groupSettingsNotifierProvider(widget.groupId).notifier)
        .leaveGroup();

    if (!mounted) return;
    context.go('/groups');
    ref.invalidate(groupListProvider);
  }

  Future<void> _confirmRemoveMember(
    AppLocalizations l10n,
    String userId,
    String displayName,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(l10n.groupSettingsRemoveMemberConfirm(displayName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancelLabel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    await ref
        .read(groupSettingsNotifierProvider(widget.groupId).notifier)
        .removeMember(userId);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(groupDetailProvider(widget.groupId));
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));
    final authAsync = ref.watch(authNotifierProvider);
    final userId = _currentUserId(authAsync);

    ref.listen<AsyncValue<void>>(
      groupSettingsNotifierProvider(widget.groupId),
      (prev, next) {
        if (next.hasError) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneric)),
          );
        }
      },
    );

    ref.listen<AsyncValue<GroupDetailModel>>(
      groupDetailProvider(widget.groupId),
      (prev, next) {
        next.whenData((d) {
          if (!_seeded) {
            _seeded = true;
            _nameController.text = d.name;
            setState(() {
              _type = d.type;
              _currency = d.currency;
              _simplifyDebts = d.simplifyDebts;
            });
          }
        });
      },
    );

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.groupSettingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: AppBar(title: Text(l10n.groupSettingsTitle)),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      data: (detail) {
        final lastAdmin = _isLastAdmin(detail, userId);
        final errorScheme = Theme.of(context).colorScheme.error;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.groupSettingsTitle)),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n.createGroupNameLabel,
                  ),
                ),
                const SizedBox(height: 16),
                GroupTypeSelector(
                  value: _type,
                  onChanged: (v) => setState(() => _type = v),
                ),
                const SizedBox(height: 16),
                CurrencyDropdown(
                  value: _currency,
                  onChanged: (v) => setState(() => _currency = v),
                ),
                const SizedBox(height: 8),
                SimplifyDebtsToggle(
                  value: _simplifyDebts,
                  onChanged: (v) => setState(() => _simplifyDebts = v),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => _onSave(l10n, detail),
                  child: Text(l10n.saveLabel),
                ),
                const SizedBox(height: 32),
                membersAsync.when(
                  data: (members) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: members
                        .map(
                          (m) => MemberListTile(
                            member: m,
                            isCurrentUser: m.userId == userId,
                            canManage: true,
                            canManageThisMember: userId == detail.createdBy ||
                                m.userId != detail.createdBy,
                            onChangeRole: (role) {
                              ref
                                  .read(
                                    groupSettingsNotifierProvider(
                                      widget.groupId,
                                    ).notifier,
                                  )
                                  .changeMemberRole(m.userId, role);
                            },
                            onRemove: () => _confirmRemoveMember(
                              l10n,
                              m.userId,
                              m.displayName,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (_, _) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.errorGeneric)),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.groupSettingsDangerZone,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: errorScheme,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: errorScheme),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton(
                        onPressed: lastAdmin
                            ? null
                            : () => _confirmLeave(l10n),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: errorScheme,
                          side: BorderSide(color: errorScheme),
                        ),
                        child: Text(l10n.groupSettingsLeaveGroup),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => _confirmDelete(l10n),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: errorScheme,
                          side: BorderSide(color: errorScheme),
                        ),
                        child: Text(l10n.groupSettingsDeleteGroup),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
