import 'package:flutter/widgets.dart';

/// Platform-agnostic banner ads (Phase 23). No interstitials or rewarded APIs.
abstract class AdHandle {
  bool get isDisposed;

  Widget get adWidget;

  void dispose();
}

enum RachaeAdSize { banner }

/// Abstract contract for ad loading. Widgets depend only on this — no `google_mobile_ads` types.
abstract class AdService {
  Future<void> initialize();

  Future<void> loadBannerAd({
    required String adUnitId,
    required RachaeAdSize size,
    required void Function(AdHandle handle) onLoaded,
    required void Function(String code, String message) onFailed,
  });

  Future<void> disposeBannerAd(AdHandle handle);
}
