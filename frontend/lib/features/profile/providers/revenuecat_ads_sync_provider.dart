import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/revenuecat/revenuecat.dart';

import 'ads_status_provider.dart';

/// Keeps a subscription to RevenueCat customer-info updates and nudges
/// [adsStatusProvider] so the UI can refresh after IAP changes (webhook may lag).
final revenueCatAdsSyncProvider = Provider<void>((ref) {
  final sub = revenueCatCustomerInfoChanged.listen((_) {
    ref.invalidate(adsStatusProvider);
  });
  ref.onDispose(sub.cancel);
});
