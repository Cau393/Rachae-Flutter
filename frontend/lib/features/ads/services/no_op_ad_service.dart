import 'package:frontend/features/ads/services/ad_service.dart';

/// Web / fallback: never loads native ads, never throws.
class NoOpAdService implements AdService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> loadBannerAd({
    required String adUnitId,
    required RachaeAdSize size,
    required void Function(AdHandle handle) onLoaded,
    required void Function(String code, String message) onFailed,
  }) async {}

  @override
  Future<void> disposeBannerAd(AdHandle handle) async {}
}
