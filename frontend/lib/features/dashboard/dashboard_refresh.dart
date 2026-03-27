import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';

/// Invalidates dashboard-related providers and waits until refetches complete so
/// balance, activity, shortcut badges, and group list cannot show stale data
/// after approve / settle / pull-to-refresh.
Future<void> refreshDashboardData(WidgetRef ref) async {
  ref.invalidate(balanceSummaryProvider);
  ref.invalidate(pendingIncomingSettlementsProvider);
  ref.invalidate(pendingOutgoingSettlementsProvider);
  ref.invalidate(pairwiseBalancesProvider);
  ref.invalidate(owedToMeExpensesProvider);
  ref.invalidate(groupListProvider);

  await Future.wait([
    ref.read(balanceSummaryProvider.future),
    ref.read(activityFeedProvider.notifier).refresh(),
    ref.read(pendingIncomingSettlementsProvider.future),
    ref.read(pendingOutgoingSettlementsProvider.future),
    ref.read(pairwiseBalancesProvider.future),
    ref.read(owedToMeExpensesProvider.future),
    ref.read(groupListProvider.future),
  ]);
}
