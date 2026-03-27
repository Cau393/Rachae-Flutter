import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/widgets/ad_banner.dart';
import 'package:frontend/features/dashboard/dashboard_refresh.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/dashboard/widgets/activity_feed.dart';
import 'package:frontend/features/dashboard/widgets/balance_summary_card.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

extension DashboardScreenL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const double _wideLayoutBreakpoint = 600;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balanceAsync = ref.watch(balanceSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.dashboardTitle),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'fab_dashboard_add_expense',
        onPressed: () => context.go('/expenses/new'),
        tooltip: context.l10n.dashboardAddExpense,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => refreshDashboardData(ref),
              child: _buildBody(context, ref, balanceAsync),
            ),
          ),
          _dashboardAdSlot(ref),
        ],
      ),
    );
  }

  /// Only mount [AdBanner] when ads status is known and user is not ad-free, so
  /// premium users have no [AdBanner] in the subtree (see placement guard tests).
  /// On web, [AdBanner] itself reserves no space (see ad_banner_widget.dart).
  Widget _dashboardAdSlot(WidgetRef ref) {
    return ref.watch(adsStatusProvider).maybeWhen(
          data: (status) =>
              status.isAdFree ? const SizedBox.shrink() : const AdBanner(),
          orElse: () => const SizedBox.shrink(),
        );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<BalanceSummaryModel> balanceAsync,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _wideLayoutBreakpoint;
        final maxH = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : MediaQuery.sizeOf(context).height;

        if (wide) {
          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: maxH,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 340,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: balanceAsync.when(
                          data: (m) => Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              BalanceSummaryCard(model: m),
                              const SizedBox(height: 12),
                              const _DashboardShortcuts(),
                            ],
                          ),
                          loading: () => const _BalanceCardSkeleton(),
                          error: (Object e, StackTrace st) =>
                              const _BalanceErrorWidget(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ActivityFeed(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }

        // NestedScrollView links header + activity list into one scrollable axis (fixes
        // nested CustomScrollView + inner ListView gesture/scroll issues on mobile web).
        return NestedScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: balanceAsync.when(
                    data: (m) => Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        BalanceSummaryCard(model: m),
                        const SizedBox(height: 12),
                        const _DashboardShortcuts(),
                      ],
                    ),
                    loading: () => const _BalanceCardSkeleton(),
                    error: (Object e, StackTrace st) =>
                        const _BalanceErrorWidget(),
                  ),
                ),
              ),
            ];
          },
          body: ColoredBox(
            color: Theme.of(context).colorScheme.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: const ActivityFeed(linkedPrimaryScroll: true),
            ),
          ),
        );
      },
    );
  }
}

class _DashboardShortcuts extends ConsumerWidget {
  const _DashboardShortcuts();

  int _pendingCount<T>(AsyncValue<List<T>> async) {
    return async.maybeWhen(data: (list) => list.length, orElse: () => 0);
  }

  Widget _badgedButton({
    required BuildContext context,
    required int count,
    required VoidCallback onPressed,
    required String label,
  }) {
    final button = SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Text(label, textAlign: TextAlign.center),
      ),
    );
    if (count <= 0) return button;
    return Badge(
      label: Text('$count'),
      child: button,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final incoming = ref.watch(pendingIncomingSettlementsProvider);
    final owed = ref.watch(owedToMeExpensesProvider);
    final pairwiseAsync = ref.watch(pairwiseBalancesProvider);
    final iOweThemCount = pairwiseAsync.maybeWhen(
      data: (list) =>
          list.where((r) => r.balanceAsMoneyAmount.isNegative).length,
      orElse: () => 0,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _badgedButton(
          context: context,
          count: _pendingCount(incoming),
          onPressed: () => context.push('/dashboard/pending-approvals'),
          label: l10n.dashboardShortcutPendingApprovals,
        ),
        const SizedBox(height: 8),
        _badgedButton(
          context: context,
          count: _pendingCount(owed),
          onPressed: () => context.push('/dashboard/owed-to-me'),
          label: l10n.dashboardShortcutOwedToYou,
        ),
        const SizedBox(height: 8),
        _badgedButton(
          context: context,
          count: iOweThemCount,
          onPressed: () => context.push('/dashboard/pending-settlements'),
          label: l10n.dashboardShortcutPendingSettlements,
        ),
      ],
    );
  }
}

class _BalanceCardSkeleton extends StatelessWidget {
  const _BalanceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    final fill = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 14,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceErrorWidget extends StatelessWidget {
  const _BalanceErrorWidget();

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.errorGeneric);
  }
}
