import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/widgets/activity_feed.dart';
import 'package:frontend/features/dashboard/widgets/balance_summary_card.dart';
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
        onPressed: () => context.go('/expenses/new'),
        tooltip: context.l10n.dashboardAddExpense,
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(balanceSummaryProvider);
          ref.invalidate(activityFeedProvider);
          await Future.wait([
            ref.read(balanceSummaryProvider.future),
            ref.read(activityFeedProvider.future),
          ]);
        },
        child: _buildBody(context, ref, balanceAsync),
      ),
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
                          data: (m) => BalanceSummaryCard(model: m),
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

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: balanceAsync.when(
                  data: (m) => BalanceSummaryCard(model: m),
                  loading: () => const _BalanceCardSkeleton(),
                  error: (Object e, StackTrace st) => const _BalanceErrorWidget(),
                ),
              ),
            ),
            SliverFillRemaining(
              hasScrollBody: true,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                child: ActivityFeed(),
              ),
            ),
          ],
        );
      },
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
