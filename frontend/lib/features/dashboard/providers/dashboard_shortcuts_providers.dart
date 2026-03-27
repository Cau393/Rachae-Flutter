import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/dashboard/models/pairwise_balance_row_model.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart'
    show dashboardRepositoryProvider;
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';

final pendingIncomingSettlementsProvider =
    FutureProvider.autoDispose<List<TransactionModel>>(
  (ref) => ref.watch(settlementRepositoryProvider).fetchPendingByRole('receiver'),
  retry: (int retryCount, Object error) => null,
);

final pendingOutgoingSettlementsProvider =
    FutureProvider.autoDispose<List<TransactionModel>>(
  (ref) => ref.watch(settlementRepositoryProvider).fetchPendingByRole('payer'),
  retry: (int retryCount, Object error) => null,
);

final pairwiseBalancesProvider =
    FutureProvider.autoDispose<List<PairwiseBalanceRowModel>>(
  (ref) => ref.watch(dashboardRepositoryProvider).fetchPairwiseBalances(),
  retry: (int retryCount, Object error) => null,
);

/// Counterparties with positive net balance (they owe you), same basis as home summary.
final owedToMeExpensesProvider =
    FutureProvider.autoDispose<List<PairwiseBalanceRowModel>>(
  (ref) => ref
      .watch(dashboardRepositoryProvider)
      .fetchPairwiseBalances(oweMeOnly: true)
      .then(
        (list) => list
            .where(
              (r) => !r.balanceAsMoneyAmount.isNegative && !r.balanceAsMoneyAmount.isZero,
            )
            .toList(),
      ),
  retry: (int retryCount, Object error) => null,
);
