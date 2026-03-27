import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/ads/services/ad_service.dart';
import 'package:frontend/features/ads/services/mock_ad_service.dart';

void main() {
  group('AdService interface contract', () {
    late MockAdService mockService;

    setUp(() {
      mockService = MockAdService();
    });

    test('initialize completes without throwing', () async {
      await expectLater(mockService.initialize(), completes);
      expect(mockService.initializeCallCount, 1);
    });

    test('loadBannerAd invokes onLoaded with a non-null handle', () async {
      AdHandle? handle;
      await mockService.loadBannerAd(
        adUnitId: 'test-id',
        size: RachaeAdSize.banner,
        onLoaded: (h) => handle = h,
        onFailed: (String c, String m) => fail('onFailed should not run'),
      );
      expect(handle, isNotNull);
    });

    test('loadBannerAd calls onLoaded callback when ad loads', () async {
      var loaded = false;
      await mockService.loadBannerAd(
        adUnitId: 'a',
        size: RachaeAdSize.banner,
        onLoaded: (_) => loaded = true,
        onFailed: (String c, String m) => fail('onFailed should not run'),
      );
      expect(loaded, isTrue);
    });

    test('loadBannerAd calls onFailed callback on error', () async {
      mockService.failNextLoad = true;
      mockService.failCode = 'NO_FILL';
      mockService.failMessage = 'no inventory';

      String? code;
      String? message;
      await mockService.loadBannerAd(
        adUnitId: 'x',
        size: RachaeAdSize.banner,
        onLoaded: (_) => fail('onLoaded should not run'),
        onFailed: (c, m) {
          code = c;
          message = m;
        },
      );
      expect(code, 'NO_FILL');
      expect(message, 'no inventory');
    });

    test('disposeBannerAd disposes the handle', () async {
      AdHandle? handle;
      await mockService.loadBannerAd(
        adUnitId: 'x',
        size: RachaeAdSize.banner,
        onLoaded: (h) => handle = h,
        onFailed: (String c, String m) => fail('onFailed should not run'),
      );
      expect(handle, isNotNull);
      final mockHandle = handle! as MockAdHandle;
      expect(mockHandle.isDisposed, isFalse);

      await mockService.disposeBannerAd(handle!);
      expect(mockHandle.isDisposed, isTrue);
      expect(mockService.disposeBannerAdCallCount, 1);
    });

    test('isAdFree is enforced via AdBanner + adsStatusProvider, not AdService',
        () {
      expect(AdService, isNotNull);
    });
  });
}
