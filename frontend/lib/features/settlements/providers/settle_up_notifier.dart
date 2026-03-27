import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/friends/providers/friend_balance_provider.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';

final settleUpNotifierProvider =
    AsyncNotifierProvider.autoDispose<SettleUpNotifier, SettlementCreateResult?>(
  SettleUpNotifier.new,
);

class SettleUpNotifier extends AsyncNotifier<SettlementCreateResult?> {
  @override
  Future<SettlementCreateResult?> build() async {
    // Keep notifier alive across await in [recordPayment]; otherwise autoDispose
    // can dispose while [createTransaction] is in flight and invalidation fails.
    ref.keepAlive();
    return null;
  }

  Future<SettlementCreateResult?> recordPayment({
    required String receiverId,
    required String amount,
    required String currency,
    String? groupId,
    String? note,
    List<String>? proofUrls,
    bool isOffset = false,
  }) async {
    state = const AsyncLoading<SettlementCreateResult?>();
    try {
      final result = await ref.read(settlementRepositoryProvider).createTransaction(
            receiverId: receiverId,
            amount: amount,
            currency: currency,
            groupId: groupId,
            note: note,
            proofUrls: proofUrls,
            isOffset: isOffset,
          );
      state = AsyncData<SettlementCreateResult?>(result);
      ref.invalidate(friendBalanceProvider(receiverId));
      // Unified dashboard refresh after settlement creation.
      ref.invalidate(balanceSummaryProvider);
      ref.invalidate(activityFeedProvider);
      ref.invalidate(pendingIncomingSettlementsProvider);
      ref.invalidate(pendingOutgoingSettlementsProvider);
      ref.invalidate(pairwiseBalancesProvider);
      ref.invalidate(owedToMeExpensesProvider);
      ref.invalidate(groupListProvider);
      return result;
    } catch (e, s) {
      state = AsyncError<SettlementCreateResult?>(e, s);
      rethrow;
    }
  }
}
