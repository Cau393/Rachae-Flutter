export 'revenuecat_common.dart';
export 'revenuecat_entitlements.dart';
export 'revenuecat_paywall.dart';

import 'revenuecat_common.dart';
import 'revenuecat_stub.dart' if (dart.library.io) 'revenuecat_io.dart' as impl;

Future<void> revenueCatConfigure() => impl.revenueCatConfigure();

Future<void> revenueCatLogIn(String djangoUserId) =>
    impl.revenueCatLogIn(djangoUserId);

Future<void> revenueCatLogOut() => impl.revenueCatLogOut();

Stream<void> get revenueCatCustomerInfoChanged =>
    impl.revenueCatCustomerInfoChanged;

Future<RevenueCatPurchaseResult> revenueCatPurchasePro(
  RevenueCatBillingPlan plan,
) =>
    impl.revenueCatPurchasePro(plan);
