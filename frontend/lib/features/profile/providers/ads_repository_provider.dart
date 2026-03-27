import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/features/profile/repositories/ads_repository.dart';

final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  return AdsRepository(ref.watch(dioProvider));
});
