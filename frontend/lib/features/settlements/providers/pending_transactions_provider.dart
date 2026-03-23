import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';

/// Pending (unconfirmed, undisputed) settlements with a given user.
/// Invalidated after confirm or dispute on the friend-detail flow.
final pendingTransactionsProvider =
    FutureProvider.autoDispose.family<List<TransactionModel>, String>(
  (ref, userId) async {
    final list = await ref
        .watch(settlementRepositoryProvider)
        .fetchTransactionsWithUser(userId, status: 'pending');
    return list;
  },
  retry: (int retryCount, Object error) => null,
);
