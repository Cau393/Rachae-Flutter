import 'package:flutter/foundation.dart';

/// AdMob banner unit IDs. Use Google test IDs in debug/test; replace prod placeholders
/// before release. Never hardcode unit IDs in widgets — use [banner] or [bannerForTests].
///
/// **Android:** when `android/app/src/main/AndroidManifest.xml` exists, add inside
/// `<application>`:
/// `<meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"
/// android:value="ca-app-pub-3940256099942544~3347511713"/>` (test) or your real App ID.
abstract final class AdUnitIds {
  AdUnitIds._();

  static const bool _isTest = !bool.fromEnvironment('dart.vm.product');

  static const String _androidBannerTest =
      'ca-app-pub-3940256099942544/6300978111';
  static const String _androidBannerProd =
      'ca-app-pub-XXXXXXXXXXXXXXXX/NNNNNNNNNN';

  static const String _iosBannerTest = 'ca-app-pub-3940256099942544/2934735716';
  static const String _iosBannerProd = 'ca-app-pub-7543427210522470/7027476418';

  /// Resolved banner unit ID for the current platform and build mode.
  static String get banner {
    if (_isTest) {
      return defaultTargetPlatform == TargetPlatform.android
          ? _androidBannerTest
          : _iosBannerTest;
    }
    return defaultTargetPlatform == TargetPlatform.android
        ? _androidBannerProd
        : _iosBannerProd;
  }

  /// Alias for tests — same resolution as [banner].
  static String bannerForTests() => banner;
}
