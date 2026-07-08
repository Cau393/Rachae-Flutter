import 'dart:async';

import 'revenuecat_common.dart';

Future<void> revenueCatConfigure() async {}

Future<void> revenueCatLogIn(String djangoUserId) async {}

Future<void> revenueCatLogOut() async {}

Stream<void> get revenueCatCustomerInfoChanged => Stream<void>.empty();

Future<RevenueCatPurchaseResult> revenueCatPurchasePro(
  RevenueCatBillingPlan plan,
) async {
  return const RevenueCatPurchaseResult(
    entitled: false,
    userCancelled: true,
  );
}

/// Restores prior App Store purchases and returns whether the ad-free
/// entitlement is active afterwards. No-op off iOS.
Future<bool> revenueCatRestorePurchases() async => false;
