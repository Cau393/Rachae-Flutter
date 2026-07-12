import 'revenuecat_common.dart';
import 'revenuecat_paywall_stub.dart'
    if (dart.library.io) 'revenuecat_paywall_io.dart' as impl;

String? get revenueCatLastPaywallDiagnostic =>
    impl.revenueCatLastPaywallDiagnostic;

Future<RevenueCatPaywallFlowResult> revenueCatPresentPaywall() =>
    impl.revenueCatPresentPaywall();

Future<RevenueCatPaywallFlowResult> revenueCatPresentPaywallIfNeeded() =>
    impl.revenueCatPresentPaywallIfNeeded();

Future<void> revenueCatPresentCustomerCenter() =>
    impl.revenueCatPresentCustomerCenter();
