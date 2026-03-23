import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepository(ref.watch(dioProvider));
});
