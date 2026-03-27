/// Set from [main] before [MobileAds.initialize]. Drives [AdRequest] NPA on iOS.
class AdTargetingConfig {
  AdTargetingConfig._();
  static final AdTargetingConfig instance = AdTargetingConfig._();

  /// When true, native loads use [AdRequest.nonPersonalizedAds].
  bool useNonPersonalizedAds = false;
}
