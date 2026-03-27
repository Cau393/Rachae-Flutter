import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';

final adsStatusProvider =
    FutureProvider.autoDispose<AdsStatusModel>(
  (ref) => ref.watch(adsRepositoryProvider).fetchAdsStatus(),
  retry: (int retryCount, Object error) => null,
);
