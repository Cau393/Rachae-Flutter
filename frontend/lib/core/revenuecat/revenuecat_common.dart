import 'package:flutter/foundation.dart';

import 'package:frontend/src/config/app_config.dart';

/// True when the app should use native IAP (RevenueCat) instead of Stripe.
bool get revenueCatNativeIos =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// True when the Purchases SDK was given a public key (via `--dart-define` or
/// dotenv). If false on iOS, native calls would crash or no-op — check this
/// before presenting paywalls or Customer Center.
bool get revenueCatNativeIosSdkReady =>
    revenueCatNativeIos && AppConfig.revenueCatIosApiKey.trim().isNotEmpty;

/// Native store package / billing period (iOS RevenueCat only in this app).
enum RevenueCatBillingPlan {
  monthly,
  yearly,
  lifetime,
}

/// Outcome of presenting the RevenueCat paywall (native SDK; facets to no-ops on web).
enum RevenueCatPaywallFlowResult {
  notPresented,
  cancelled,
  error,
  purchased,
  restored,
}

/// Outcome of a native purchase attempt (for UI branching only).
class RevenueCatPurchaseResult {
  const RevenueCatPurchaseResult({
    required this.entitled,
    required this.userCancelled,
  });

  /// [kRachaeProEntitlementId] is active after purchase.
  final bool entitled;

  /// User dismissed the Apple payment sheet (no error snackbar).
  final bool userCancelled;
}
