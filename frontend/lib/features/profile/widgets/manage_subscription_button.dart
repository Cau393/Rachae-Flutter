import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/core/revenuecat/revenuecat.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ManageSubscriptionButton extends ConsumerStatefulWidget {
  const ManageSubscriptionButton({
    super.key,
    required this.model,
  });

  final AdsStatusModel model;

  @override
  ConsumerState<ManageSubscriptionButton> createState() =>
      _ManageSubscriptionButtonState();
}

class _ManageSubscriptionButtonState
    extends ConsumerState<ManageSubscriptionButton> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _portalPending = false;

  static final Uri _appleSubscriptionsUri =
      Uri.parse('https://apps.apple.com/account/subscriptions');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _portalPending) {
      if (!mounted) return;
      setState(() => _portalPending = false);
      unawaited(_syncAndRefresh());
    }
  }

  /// Pulls fresh entitlement state from the backend's RevenueCat sync
  /// endpoint (plan changes/cancellations made in the App Store sheet or
  /// Stripe portal are otherwise only reflected after a webhook arrives),
  /// then refreshes the providers.
  Future<void> _syncAndRefresh() async {
    try {
      await ref.read(adsRepositoryProvider).syncAdsStatus();
    } catch (_) {
      // Fall back to whatever the regular status fetch returns.
    }
    if (!mounted) return;
    ref.invalidate(adsStatusProvider);
    ref.invalidate(profileNotifierProvider);
  }

  String _planName(AppLocalizations l10n, AdsStatusModel m) {
    if (m.planType == 'monthly') return l10n.profileAdFreeMonthlyLabel;
    if (m.planType == 'yearly') return l10n.profileAdFreeYearlyLabel;
    if (m.planType == 'lifetime') return l10n.profileAdFreeLifetimeLabel;
    return l10n.profileAdFreePlanUnknown;
  }

  Future<void> _openStripePortal(BuildContext context, AppLocalizations l10n) async {
    final url = await ref.read(adsRepositoryProvider).createPortalSession();
    final uri = Uri.parse(url);
    if (!context.mounted) return;
    final canLaunch = await canLaunchUrl(uri);
    if (!context.mounted) return;
    if (!canLaunch) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.profileCheckoutCannotOpenUrl)),
      );
      return;
    }
    setState(() => _portalPending = true);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!context.mounted) return;
    if (!launched) {
      setState(() => _portalPending = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.profileCheckoutCannotOpenUrl)),
      );
    }
  }

  /// Opens Apple's "Manage Subscriptions" page — used when the current plan
  /// was purchased via the App Store (no Stripe customer) and the RevenueCat
  /// Customer Center UI is unavailable or not applicable.
  Future<void> _openAppleSubscriptions(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final canLaunch = await canLaunchUrl(_appleSubscriptionsUri);
    if (!context.mounted) return;
    if (!canLaunch) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.profileManageSubscriptionAppleUrlError)),
      );
      return;
    }
    setState(() => _portalPending = true);
    final launched = await launchUrl(
      _appleSubscriptionsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!context.mounted) return;
    if (!launched) {
      setState(() => _portalPending = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.profileManageSubscriptionAppleUrlError)),
      );
    }
  }

  Future<void> _openCustomerCenter(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (!mounted) return;
    if (!revenueCatNativeIosSdkReady) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.profileRevenueCatMissingApiKey)),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      await revenueCatPresentCustomerCenter();
      if (!mounted) return;
      await _syncAndRefresh();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.unknownError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final m = widget.model;
    final expires = m.planExpiresAt;
    final planLabel = _planName(l10n, m);
    // iOS native: always use RevenueCat / App Store flows — never open Stripe
    // in an external browser, even when the backend still exposes the portal
    // (e.g. user originally checked out on web or legacy Stripe data).
    final showStripePortal =
        m.stripePortalAvailable && !revenueCatNativeIos;
    final showIosRevenueCat = revenueCatNativeIos;
    // Off native iOS, a subscription with no Stripe customer (no portal
    // available) can only have come from the App Store — offer Apple's
    // subscription management page directly instead of leaving the user
    // stuck on "managed elsewhere".
    final showAppleSubscriptionsLink =
        !showStripePortal && !showIosRevenueCat && !m.stripePortalAvailable;

    final isCanceled = m.subscriptionStatus == 'canceled';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              isCanceled ? Icons.info_outline : Icons.check_circle_outline,
              size: 18,
              color: isCanceled
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isCanceled
                    ? l10n.profileAdFreeCanceled
                    : l10n.profileAdFreeActive,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCanceled
                          ? Theme.of(context).colorScheme.error
                          : null,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.profileAdFreeCurrentPlanLabel(planLabel),
          style: Theme.of(context).textTheme.titleSmall,
        ),
        if (expires != null) ...[
          const SizedBox(height: 8),
          Text(
            isCanceled
                ? l10n.profileAdFreeAccessUntil(
                    DateFormat.yMMMd().format(expires.toLocal()),
                  )
                : l10n.profileAdFreeRenews(
                    DateFormat.yMMMd().format(expires.toLocal()),
                  ),
          ),
        ],
        const SizedBox(height: 12),
        if (showStripePortal) ...[
          OutlinedButton(
            onPressed: _isLoading
                ? null
                : () => _openStripePortal(context, l10n),
            child: Text(l10n.profileManageSubscriptionButton),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profilePlanChangeStripePortalFootnote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (showIosRevenueCat) ...[
          OutlinedButton(
            onPressed: _isLoading
                ? null
                : () => _openCustomerCenter(context, l10n),
            child: Text(l10n.profileManageSubscriptionButton),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileIosSubscriptionChangeFootnote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
        if (showAppleSubscriptionsLink) ...[
          OutlinedButton(
            onPressed: () => _openAppleSubscriptions(context, l10n),
            child: Text(l10n.profileManageSubscriptionButton),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.profileIosSubscriptionChangeFootnote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
        if (!showStripePortal && !showIosRevenueCat && !showAppleSubscriptionsLink)
          Text(
            l10n.profileSubscriptionManagedElsewhere,
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
  }
}
