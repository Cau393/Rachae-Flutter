import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:frontend/features/ads/ad_targeting_config.dart';
import 'package:frontend/features/ads/services/ad_service.dart';

class _BannerAdHandle implements AdHandle {
  _BannerAdHandle(this._ad);

  final BannerAd _ad;

  @override
  bool isDisposed = false;

  @override
  Widget get adWidget => AdWidget(ad: _ad);

  @override
  void dispose() {
    if (isDisposed) return;
    isDisposed = true;
    _ad.dispose();
  }
}

/// Real AdMob implementation — import `google_mobile_ads` only here.
class AdMobAdService implements AdService {
  @override
  Future<void> initialize() async {
    // [main.dart] calls MobileAds.instance.initialize(); keep this as no-op to avoid duplication.
  }

  static AdSize _mapSize(RachaeAdSize size) {
    switch (size) {
      case RachaeAdSize.banner:
        return AdSize.banner;
    }
  }

  @override
  Future<void> loadBannerAd({
    required String adUnitId,
    required RachaeAdSize size,
    required void Function(AdHandle handle) onLoaded,
    required void Function(String code, String message) onFailed,
  }) async {
    final banner = BannerAd(
      adUnitId: adUnitId,
      size: _mapSize(size),
      request: AdRequest(
        nonPersonalizedAds: AdTargetingConfig.instance.useNonPersonalizedAds,
      ),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          final loaded = ad as BannerAd;
          onLoaded(_BannerAdHandle(loaded));
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
          onFailed('${error.code}', error.message);
        },
      ),
    );

    await banner.load();
  }

  @override
  Future<void> disposeBannerAd(AdHandle handle) async {
    handle.dispose();
  }
}
