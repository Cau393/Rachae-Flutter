import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';

import 'package:frontend/src/config/app_config.dart';

import 'revenuecat_common.dart';
import 'revenuecat_entitlements.dart';

RevenueCatPaywallFlowResult _mapPaywallResult(PaywallResult r) {
  switch (r) {
    case PaywallResult.notPresented:
      return RevenueCatPaywallFlowResult.notPresented;
    case PaywallResult.cancelled:
      return RevenueCatPaywallFlowResult.cancelled;
    case PaywallResult.error:
      return RevenueCatPaywallFlowResult.error;
    case PaywallResult.purchased:
      return RevenueCatPaywallFlowResult.purchased;
    case PaywallResult.restored:
      return RevenueCatPaywallFlowResult.restored;
  }
}

Future<Offerings?> _fetchOfferings() async {
  if (kIsWeb || !Platform.isIOS) return null;
  if (AppConfig.revenueCatIosApiKey.trim().isEmpty) return null;
  return Purchases.getOfferings();
}

/// Diagnostic set right before [revenueCatPresentPaywall] or
/// [revenueCatPresentPaywallIfNeeded] returns
/// [RevenueCatPaywallFlowResult.notConfigured]; null otherwise. Lets the UI
/// surface *why* IAP looks unconfigured (e.g. TestFlight) without changing
/// the result enum.
String? _lastPaywallDiagnostic;

String? get revenueCatLastPaywallDiagnostic => _lastPaywallDiagnostic;

/// Calls StoreKit directly for the two known product ids so the
/// "not configured" diagnostic can show whether the App Store even resolves
/// them, independent of RevenueCat's offerings config. Never throws.
Future<String> _probeStoreProductsSuffix() async {
  try {
    final products = await Purchases.getProducts(
      [kRachaeProIosMonthlyProductId, kRachaeProIosYearlyProductId],
    );
    return 'storeProducts=${products.length}/2';
  } catch (e) {
    debugPrint('[RevenueCat] getProducts probe failed: $e');
    return 'storeProducts=?/2';
  }
}

Future<RevenueCatPaywallFlowResult> _notConfigured({
  Offerings? offerings,
  PlatformException? exception,
}) async {
  final storeSuffix = await _probeStoreProductsSuffix();
  final String diagnostic;
  if (exception != null) {
    final code = PurchasesErrorHelper.getErrorCode(exception).name;
    final message = exception.message ?? '';
    final trimmed =
        message.length > 60 ? '${message.substring(0, 60)}...' : message;
    diagnostic = trimmed.isEmpty
        ? 'err=$code $storeSuffix'
        : 'err=$code msg="$trimmed" $storeSuffix';
    debugPrint('[RevenueCat] presentPaywall: notConfigured '
        '(configurationError) $diagnostic full=$exception');
  } else {
    diagnostic = 'offerings=${offerings?.all.length ?? 0} current=null '
        '$storeSuffix';
    debugPrint('[RevenueCat] presentPaywall: notConfigured '
        '(offerings.current is null) $diagnostic');
  }
  _lastPaywallDiagnostic = diagnostic;
  return RevenueCatPaywallFlowResult.notConfigured;
}

Future<RevenueCatPaywallFlowResult> revenueCatPresentPaywall() async {
  _lastPaywallDiagnostic = null;
  if (kIsWeb || !Platform.isIOS) {
    return RevenueCatPaywallFlowResult.notPresented;
  }
  try {
    final offerings = await _fetchOfferings();
    final current = offerings?.current;
    if (current == null) {
      return await _notConfigured(offerings: offerings);
    }
    final r = await RevenueCatUI.presentPaywall(offering: current);
    return _mapPaywallResult(r);
  } on PlatformException catch (e) {
    if (PurchasesErrorHelper.getErrorCode(e) ==
        PurchasesErrorCode.configurationError) {
      return await _notConfigured(exception: e);
    }
    debugPrint('[RevenueCat] presentPaywall failed: $e');
    return RevenueCatPaywallFlowResult.error;
  } catch (e, st) {
    debugPrint('[RevenueCat] presentPaywall failed: $e\n$st');
    return RevenueCatPaywallFlowResult.error;
  }
}

Future<RevenueCatPaywallFlowResult> revenueCatPresentPaywallIfNeeded() async {
  _lastPaywallDiagnostic = null;
  if (kIsWeb || !Platform.isIOS) {
    return RevenueCatPaywallFlowResult.notPresented;
  }
  try {
    final offerings = await _fetchOfferings();
    final current = offerings?.current;
    if (current == null) {
      return await _notConfigured(offerings: offerings);
    }
    final r = await RevenueCatUI.presentPaywallIfNeeded(
      kRachaeProEntitlementId,
      offering: current,
    );
    return _mapPaywallResult(r);
  } on PlatformException catch (e) {
    if (PurchasesErrorHelper.getErrorCode(e) ==
        PurchasesErrorCode.configurationError) {
      return await _notConfigured(exception: e);
    }
    debugPrint('[RevenueCat] presentPaywallIfNeeded failed: $e');
    return RevenueCatPaywallFlowResult.error;
  } catch (e, st) {
    debugPrint('[RevenueCat] presentPaywallIfNeeded failed: $e\n$st');
    return RevenueCatPaywallFlowResult.error;
  }
}

Future<void> revenueCatPresentCustomerCenter() async {
  if (kIsWeb || !Platform.isIOS) return;
  if (AppConfig.revenueCatIosApiKey.trim().isEmpty) return;
  try {
    await RevenueCatUI.presentCustomerCenter();
  } catch (e, st) {
    debugPrint('[RevenueCat] presentCustomerCenter failed: $e\n$st');
    rethrow;
  }
}
