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

Future<Offering?> _currentOffering() async {
  if (kIsWeb || !Platform.isIOS) return null;
  if (AppConfig.revenueCatIosApiKey.trim().isEmpty) return null;
  final offerings = await Purchases.getOfferings();
  return offerings.current;
}

Future<RevenueCatPaywallFlowResult> revenueCatPresentPaywall() async {
  if (kIsWeb || !Platform.isIOS) {
    return RevenueCatPaywallFlowResult.notPresented;
  }
  try {
    final current = await _currentOffering();
    if (current == null) {
      return RevenueCatPaywallFlowResult.notConfigured;
    }
    final r = await RevenueCatUI.presentPaywall(offering: current);
    return _mapPaywallResult(r);
  } on PlatformException catch (e) {
    if (PurchasesErrorHelper.getErrorCode(e) ==
        PurchasesErrorCode.configurationError) {
      debugPrint('[RevenueCat] presentPaywall: offerings not configured '
          '(no App Store products in RevenueCat dashboard).');
      return RevenueCatPaywallFlowResult.notConfigured;
    }
    debugPrint('[RevenueCat] presentPaywall failed: $e');
    return RevenueCatPaywallFlowResult.error;
  } catch (e, st) {
    debugPrint('[RevenueCat] presentPaywall failed: $e\n$st');
    return RevenueCatPaywallFlowResult.error;
  }
}

Future<RevenueCatPaywallFlowResult> revenueCatPresentPaywallIfNeeded() async {
  if (kIsWeb || !Platform.isIOS) {
    return RevenueCatPaywallFlowResult.notPresented;
  }
  try {
    final current = await _currentOffering();
    if (current == null) {
      return RevenueCatPaywallFlowResult.notConfigured;
    }
    final r = await RevenueCatUI.presentPaywallIfNeeded(
      kRachaeProEntitlementId,
      offering: current,
    );
    return _mapPaywallResult(r);
  } on PlatformException catch (e) {
    if (PurchasesErrorHelper.getErrorCode(e) ==
        PurchasesErrorCode.configurationError) {
      debugPrint('[RevenueCat] presentPaywallIfNeeded: offerings not '
          'configured (no App Store products in RevenueCat dashboard).');
      return RevenueCatPaywallFlowResult.notConfigured;
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
