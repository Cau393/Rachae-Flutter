import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';

/// Fetches how much [receiverId] owes the current user outside [excludeGroupId].
final offsetCreditPreviewProvider = FutureProvider.autoDispose
    .family<({String credit, String currency}), ({String receiverId, String excludeGroupId})>(
  (ref, args) => ref.read(settlementRepositoryProvider).fetchOffsetCreditPreview(
        withUserId: args.receiverId,
        excludeGroupId: args.excludeGroupId,
      ),
);
