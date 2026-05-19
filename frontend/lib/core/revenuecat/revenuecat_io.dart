import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:frontend/src/config/app_config.dart';

import 'revenuecat_common.dart';
import 'revenuecat_entitlements.dart';

String? _lastRevenueCatAppUserId;

final StreamController<void> _customerInfoChanged =
    StreamController<void>.broadcast();

/// Fires when RevenueCat pushes an updated [CustomerInfo] (renewal, restore, etc.).
Stream<void> get revenueCatCustomerInfoChanged => _customerInfoChanged.stream;

void _emitCustomerInfoChanged() {
  if (_customerInfoChanged.isClosed) return;
  _customerInfoChanged.add(null);
}

bool _customerInfoListenerAttached = false;

void _ensureCustomerInfoListener() {
  if (_customerInfoListenerAttached) return;
  if (kIsWeb || !Platform.isIOS) return;
  if (AppConfig.revenueCatIosApiKey.trim().isEmpty) return;
  _customerInfoListenerAttached = true;
  Purchases.addCustomerInfoUpdateListener((_) => _emitCustomerInfoChanged());
}

Package? _packageWithStoreProductId(Offering offering, String storeProductId) {
  for (final p in offering.availablePackages) {
    if (p.storeProduct.identifier == storeProductId) {
      return p;
    }
  }
  return null;
}

Package? _packageForPlan(Offering current, RevenueCatBillingPlan plan) {
  switch (plan) {
    case RevenueCatBillingPlan.monthly:
      return _packageWithStoreProductId(current, kRachaeProIosMonthlyProductId) ??
          current.monthly ??
          current.getPackage('monthly');
    case RevenueCatBillingPlan.yearly:
      return _packageWithStoreProductId(current, kRachaeProIosYearlyProductId) ??
          current.annual ??
          current.getPackage('annual') ??
          current.getPackage('yearly');
    case RevenueCatBillingPlan.lifetime:
      return current.lifetime ??
          current.getPackage('lifetime') ??
          current.getPackage('rc_lifetime');
  }
}

bool _hasRachaePro(CustomerInfo customerInfo) =>
    customerInfo.entitlements.all[kRachaeProEntitlementId]?.isActive == true;

Future<void> revenueCatConfigure() async {
  if (kIsWeb || !Platform.isIOS) return;
  final key = AppConfig.revenueCatIosApiKey.trim();
  if (key.isEmpty) {
    debugPrint(
      '[RevenueCat] REVENUECAT_IOS_API_KEY is empty — skipping configure. '
      'On device, .env is not on the filesystem; use '
      '`flutter run --dart-define-from-file=../.env` (from frontend/) or '
      '`--dart-define=REVENUECAT_IOS_API_KEY=…`.',
    );
    return;
  }
  await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);
  final configuration = PurchasesConfiguration(key);
  await Purchases.configure(configuration);
  _ensureCustomerInfoListener();
}

Future<void> revenueCatLogIn(String djangoUserId) async {
  if (kIsWeb || !Platform.isIOS) return;
  if (AppConfig.revenueCatIosApiKey.trim().isEmpty) return;
  if (_lastRevenueCatAppUserId == djangoUserId) return;
  await Purchases.logIn(djangoUserId);
  _lastRevenueCatAppUserId = djangoUserId;
  _ensureCustomerInfoListener();
}

Future<void> revenueCatLogOut() async {
  if (kIsWeb || !Platform.isIOS) return;
  if (AppConfig.revenueCatIosApiKey.trim().isEmpty) return;
  try {
    await Purchases.logOut();
    _lastRevenueCatAppUserId = null;
  } on PlatformException catch (e, st) {
    final code = PurchasesErrorHelper.getErrorCode(e);
    if (code == PurchasesErrorCode.logOutWithAnonymousUserError) {
      _lastRevenueCatAppUserId = null;
      return;
    }
    debugPrint('[RevenueCat] logOut failed: $e\n$st');
  }
}

Future<RevenueCatPurchaseResult> revenueCatPurchasePro(
  RevenueCatBillingPlan plan,
) async {
  if (kIsWeb || !Platform.isIOS) {
    return const RevenueCatPurchaseResult(
      entitled: false,
      userCancelled: true,
    );
  }
  if (AppConfig.revenueCatIosApiKey.trim().isEmpty) {
    return const RevenueCatPurchaseResult(
      entitled: false,
      userCancelled: false,
    );
  }
  try {
    final offerings = await Purchases.getOfferings();
    final current = offerings.current;
    if (current == null) {
      return const RevenueCatPurchaseResult(
        entitled: false,
        userCancelled: false,
      );
    }
    final package = _packageForPlan(current, plan);
    if (package == null) {
      return const RevenueCatPurchaseResult(
        entitled: false,
        userCancelled: false,
      );
    }
    final purchaseResult =
        await Purchases.purchase(PurchaseParams.package(package));
    final customerInfo = purchaseResult.customerInfo;
    final entitled = _hasRachaePro(customerInfo);
    if (entitled) {
      _emitCustomerInfoChanged();
    }
    return RevenueCatPurchaseResult(
      entitled: entitled,
      userCancelled: false,
    );
  } on PlatformException catch (e) {
    if (PurchasesErrorHelper.getErrorCode(e) ==
        PurchasesErrorCode.purchaseCancelledError) {
      return const RevenueCatPurchaseResult(
        entitled: false,
        userCancelled: true,
      );
    }
    rethrow;
  }
}
