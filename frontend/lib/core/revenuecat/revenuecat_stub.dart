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
