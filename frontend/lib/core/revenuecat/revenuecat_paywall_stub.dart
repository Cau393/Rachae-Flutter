import 'revenuecat_common.dart';

String? get revenueCatLastPaywallDiagnostic => null;

Future<RevenueCatPaywallFlowResult> revenueCatPresentPaywall() async =>
    RevenueCatPaywallFlowResult.notPresented;

Future<RevenueCatPaywallFlowResult> revenueCatPresentPaywallIfNeeded() async =>
    RevenueCatPaywallFlowResult.notPresented;

Future<void> revenueCatPresentCustomerCenter() async {}
