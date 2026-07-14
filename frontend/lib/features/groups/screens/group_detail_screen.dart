import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/providers/group_balances_provider.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart';
import 'package:frontend/features/groups/providers/group_settings_notifier.dart';
import 'package:frontend/features/groups/widgets/balance_list_tile.dart';
import 'package:frontend/features/groups/widgets/group_expense_list.dart';
import 'package:frontend/features/groups/widgets/group_header.dart';
import 'package:frontend/features/groups/widgets/group_net_balance_chip.dart';
import 'package:frontend/features/groups/widgets/member_list_tile.dart';
import 'package:frontend/features/groups/widgets/settlement_suggestion_tile.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class GroupDetailScreen extends ConsumerStatefulWidget {
  const GroupDetailScreen({super.key, required this.groupId});

  final String groupId;

  @override
  ConsumerState<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends ConsumerState<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabTick);
  }

  void _onTabTick() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabTick);
    _tabController.dispose();
    super.dispose();
  }

  String get _groupId => widget.groupId;

  String _currentUserId(AsyncValue<AuthState> auth) {
    return switch (auth.value) {
      AuthStateAuthenticated(:final user) => user.id,
      _ => '',
    };
  }

  String _currentUserRole(GroupDetailModel? detail, String userId) {
    if (detail == null || userId.isEmpty) return 'VIEWER';
    return detail.memberByUserId(userId)?.role ?? 'VIEWER';
  }

  Future<void> _onRefresh() async {
    ref.invalidate(groupDetailProvider(_groupId));
    ref.invalidate(groupMembersProvider(_groupId));
    ref.invalidate(groupBalancesProvider(_groupId));
    await ref.read(groupDetailProvider(_groupId).future);
  }

  Widget? _buildFab({
    required AppLocalizations l10n,
    required int tabIndex,
  }) {
    if (tabIndex == 0) {
      return FloatingActionButton(
        heroTag: 'fab_group_detail_add_expense',
        onPressed: () {
          final uri = Uri(
            path: '/expenses/new',
            queryParameters: <String, String>{'group_id': _groupId},
          );
          context.go(uri.toString());
        },
        tooltip: l10n.groupDetailAddExpense,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

  Widget _expensesTab(AppLocalizations l10n) {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverFillRemaining(
            hasScrollBody: true,
            child: GroupExpenseList(groupId: _groupId),
          ),
        ],
      ),
    );
  }

  Widget _balancesTab(AppLocalizations l10n, String currentUserId) {
    final async = ref.watch(groupBalancesProvider(_groupId));
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: async.when(
        data: (record) {
          if (record.balances.isEmpty && record.suggestions.isEmpty) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.groupDetailNoDebts)),
                ),
              ],
            );
          }
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              ...record.balances.map(
                (b) => BalanceListTile(
                  balance: b,
                  currency: record.currency,
                  isCurrentUser: b.userId == currentUserId,
                ),
              ),
              if (record.suggestions.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    l10n.groupDetailSimplifiedDebts,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ...record.suggestions.map(
                  (s) => SettlementSuggestionTile(
                    groupId: _groupId,
                    suggestion: s,
                    currentUserId: currentUserId,
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.errorGeneric)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _membersTab(
    AppLocalizations l10n,
    String currentUserId,
    String role,
    String groupCreatorUserId,
  ) {
    final async = ref.watch(groupMembersProvider(_groupId));
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: async.when(
        data: (members) {
          return CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (role == 'ADMIN')
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: FilledButton.icon(
                      onPressed: () async {
                        final addedCount = await context.push<int>(
                          '/groups/$_groupId/add-members',
                        );
                        if (!mounted) return;
                        if (addedCount != null && addedCount > 0) {
                          _tabController.animateTo(2);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                l10n.groupAddMembersAddedSuccess(addedCount),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.person_add_outlined),
                      label: Text(l10n.groupAddFriendsButton),
                    ),
                  ),
                ),
              if (members.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(child: Text(l10n.groupsEmpty)),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final m = members[i];
                      return MemberListTile(
                        member: m,
                        isCurrentUser: m.userId == currentUserId,
                        canManage: role == 'ADMIN',
                        canManageThisMember: currentUserId == groupCreatorUserId ||
                            m.userId != groupCreatorUserId,
                        onChangeRole: (newRole) {
                          ref
                              .read(
                                groupSettingsNotifierProvider(_groupId)
                                    .notifier,
                              )
                              .changeMemberRole(m.userId, newRole);
                        },
                        onRemove: () {
                          ref
                              .read(
                                groupSettingsNotifierProvider(_groupId)
                                    .notifier,
                              )
                              .removeMember(m.userId);
                        },
                      );
                    },
                    childCount: members.length,
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.errorGeneric)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(groupDetailProvider(_groupId));
    final profileAsync = ref.watch(profileNotifierProvider);
    final authAsync = ref.watch(authNotifierProvider);
    final djangoUserId = profileAsync.maybeWhen(
      data: (p) => p.id,
      orElse: () => '',
    );
    final userId = djangoUserId.isNotEmpty
        ? djangoUserId
        : _currentUserId(authAsync);

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(title: Text(l10n.loadingLabel)),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, s) => Scaffold(
        appBar: AppBar(title: Text(l10n.groupsTitle)),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      data: (detail) {
        ref.watch(groupSettingsNotifierProvider(_groupId));
        final role = _currentUserRole(detail, userId);
        Widget? balanceChip;
        if (userId.isNotEmpty) {
          for (final b in detail.netBalances) {
            if (b.userId == userId) {
              balanceChip = GroupNetBalanceChip(
                rawNetBalance: b.netBalance,
                currency: detail.currency,
                l10n: l10n,
              );
              break;
            }
          }
        }
        return Scaffold(
          appBar: AppBar(
            title: Text(detail.name),
            actions: [
              if (role == 'ADMIN')
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: l10n.groupDetailSettings,
                  onPressed: () => context.go('/groups/$_groupId/settings'),
                ),
            ],
          ),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GroupHeader(model: detail, balanceChip: balanceChip),
              TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: l10n.groupDetailTabExpenses),
                  Tab(text: l10n.groupDetailTabBalances),
                  Tab(text: l10n.groupDetailTabMembers),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _expensesTab(l10n),
                    _balancesTab(l10n, userId),
                    _membersTab(l10n, userId, role, detail.createdBy),
                  ],
                ),
              ),
            ],
          ),
          floatingActionButton: _buildFab(
            l10n: l10n,
            tabIndex: _tabController.index,
          ),
        );
      },
    );
  }
}
