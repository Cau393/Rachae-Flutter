import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:frontend/features/ads/ad_targeting_config.dart';

/// Requests App Tracking Transparency (iOS only) and initializes AdMob.
///
/// Must be called **after** the first frame has rendered and the app is in
/// the `resumed` lifecycle state — calling `requestTrackingAuthorization`
/// before the app is fully active is unreliable and can silently skip the
/// system prompt (this was the root cause of the Guideline 5.1.2(i)
/// rejection; see `docs/app-review-rejection-plan-2026-07-07.md` Issue 4).
///
/// Web and Android behavior is unchanged from the previous `main()`-time
/// implementation — only the *timing* changed for iOS.
Future<void> initializeNativeMobileAds() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    var status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      status = await AppTrackingTransparency.requestTrackingAuthorization();
    }
    AdTargetingConfig.instance.useNonPersonalizedAds =
        status != TrackingStatus.authorized;
  } else {
    AdTargetingConfig.instance.useNonPersonalizedAds = false;
  }
  await MobileAds.instance.initialize();
}
