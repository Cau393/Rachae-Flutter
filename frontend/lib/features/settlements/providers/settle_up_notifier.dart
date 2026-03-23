import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/friends/providers/friend_balance_provider.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';

final settleUpNotifierProvider =
    AsyncNotifierProvider.autoDispose<SettleUpNotifier, TransactionModel?>(
  SettleUpNotifier.new,
);

class SettleUpNotifier extends AsyncNotifier<TransactionModel?> {
  @override
  Future<TransactionModel?> build() async => null;

  Future<TransactionModel?> recordPayment({
    required String receiverId,
    required String amount,
    required String currency,
    String? groupId,
    String? note,
  }) async {
    state = const AsyncLoading<TransactionModel?>();
    try {
      final transaction = await ref.read(settlementRepositoryProvider).createTransaction(
            receiverId: receiverId,
            amount: amount,
            currency: currency,
            groupId: groupId,
            note: note,
          );
      state = AsyncData<TransactionModel?>(transaction);
      ref.invalidate(friendBalanceProvider(receiverId));
      ref.invalidate(balanceSummaryProvider);
      ref.invalidate(activityFeedProvider);
      return transaction;
    } catch (e, s) {
      state = AsyncError<TransactionModel?>(e, s);
      rethrow;
    }
  }
}
