import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/revenuecat/revenuecat.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class AdFreeUpgradeCard extends ConsumerStatefulWidget {
  const AdFreeUpgradeCard({super.key});

  @override
  ConsumerState<AdFreeUpgradeCard> createState() => _AdFreeUpgradeCardState();
}

class _AdFreeUpgradeCardState extends ConsumerState<AdFreeUpgradeCard>
    with WidgetsBindingObserver {
  String _plan = 'monthly';
  bool _isLoading = false;
  bool _isCheckoutPending = false;

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
    if (state == AppLifecycleState.resumed && _isCheckoutPending) {
      if (!mounted) return;
      setState(() {
        _isCheckoutPending = false;
        _isLoading = true;
      });
      unawaited(_syncAdsStatusAndRefresh());
    }
  }

  Future<void> _syncAdsStatusAndRefresh() async {
    try {
      await ref.read(adsRepositoryProvider).syncAdsStatus();
    } catch (_) {
      // Sync is best-effort here — the periodic adsStatusProvider fetch and
      // any pending webhook will still reconcile state eventually.
    } finally {
      ref.invalidate(adsStatusProvider);
      ref.invalidate(profileNotifierProvider);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _checkoutErrorMessage(AppLocalizations l10n, Object error) {
    if (error is ApiException) {
      if (error.statusCode == 400) {
        final message = error.message.toLowerCase();
        if (message.contains('already') && message.contains('subscription')) {
          return l10n.profileCheckoutAlreadySubscribed;
        }
      }
      return l10n.profileCheckoutSessionError;
    }
    return l10n.unknownError;
  }

  Future<void> _onUpgradePressed(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      if (revenueCatNativeIos) {
        if (!revenueCatNativeIosSdkReady) {
          if (!context.mounted) return;
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(l10n.profileRevenueCatMissingApiKey)),
          );
          return;
        }
        final result = await revenueCatPresentPaywall();
        if (!context.mounted) return;
        switch (result) {
          case RevenueCatPaywallFlowResult.purchased:
          case RevenueCatPaywallFlowResult.restored:
            await _syncAdsStatusAndRefresh();
            break;
          case RevenueCatPaywallFlowResult.cancelled:
          case RevenueCatPaywallFlowResult.notPresented:
            break;
          case RevenueCatPaywallFlowResult.notConfigured:
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(content: Text(l10n.profileIapNotConfigured)),
            );
            break;
          case RevenueCatPaywallFlowResult.error:
            ScaffoldMessenger.maybeOf(context)?.showSnackBar(
              SnackBar(content: Text(l10n.profileIapOfferingsUnavailable)),
            );
            break;
        }
        return;
      }

      final url = await ref
          .read(adsRepositoryProvider)
          .createCheckoutSession(plan: _plan);
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

      setState(() => _isCheckoutPending = true);
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!context.mounted) return;
      if (!launched) {
        setState(() => _isCheckoutPending = false);
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.profileCheckoutCannotOpenUrl)),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckoutPending = false);
      }
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(_checkoutErrorMessage(l10n, e))),
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
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (revenueCatNativeIos) ...[
              FilledButton(
                onPressed: _isLoading
                    ? null
                    : () => _onUpgradePressed(context, l10n),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: onPrimary,
                        ),
                      )
                    : Text(l10n.profileSeeRachaeProPlansButton),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.adFreeCancelAnytime,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.adFreeMonthlyPlanOption),
                    selected: _plan == 'monthly',
                    onSelected: _isLoading
                        ? null
                        : (_) => setState(() => _plan = 'monthly'),
                  ),
                  ChoiceChip(
                    label: Text(l10n.adFreeYearlyPlanOption),
                    selected: _plan == 'yearly',
                    onSelected: _isLoading
                        ? null
                        : (_) => setState(() => _plan = 'yearly'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed:
                    _isLoading ? null : () => _onUpgradePressed(context, l10n),
                child: _isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: onPrimary,
                        ),
                      )
                    : Text(l10n.profileUpgradeButton),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
