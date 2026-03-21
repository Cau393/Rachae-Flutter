import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/models/group_balance_model.dart';
import 'package:frontend/features/groups/models/settlement_suggestion_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';

typedef GroupBalancesRecord = ({
  List<GroupBalanceModel> balances,
  List<SettlementSuggestionModel> suggestions,
  String currency,
});

final groupBalancesProvider =
    FutureProvider.autoDispose.family<GroupBalancesRecord, String>(
  (ref, groupId) async {
    final repo = ref.watch(groupRepositoryProvider);
    final results = await Future.wait([
      repo.fetchGroupBalances(groupId),
      repo.fetchSimplifiedBalances(groupId),
    ]);
    final balancesResult =
        results[0] as ({List<GroupBalanceModel> balances, String currency});
    final simplified = results[1]
        as ({bool simplifyDebts, List<SettlementSuggestionModel> suggestions});
    return (
      balances: balancesResult.balances,
      suggestions: simplified.suggestions,
      currency: balancesResult.currency,
    );
  },
  retry: (int retryCount, Object error) => null,
);
