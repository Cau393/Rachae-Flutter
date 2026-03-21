import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/repositories/dashboard_repository.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.watch(dioProvider));
});

/// Invalidation refetches (e.g. after new expense). Retries disabled — same as [currencyListProvider].
final balanceSummaryProvider = FutureProvider.autoDispose<BalanceSummaryModel>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchBalanceSummary(),
  retry: (int retryCount, Object error) => null,
);
