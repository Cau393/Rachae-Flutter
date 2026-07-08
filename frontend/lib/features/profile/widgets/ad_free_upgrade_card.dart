import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/revenuecat/revenuecat.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/features/profile/providers/profile_notifier.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Yearly-vs-monthly savings shown as a badge on the yearly plan chip
/// (Stripe/web plan selector only). Derived from the static prices baked
/// into [AppLocalizations.adFreeMonthlyPlanOption] /
/// `adFreeYearlyPlanOption` (R$ 4.99/mo, R$ 29.99/yr) — keep this in sync if
/// those prices ever change.
const int _yearlyPlanSavingsPercent = 50;

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
  bool _isRestoring = false;

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

  /// Syncs entitlement with the backend after a purchase/restore, then
  /// invalidates the ads/profile providers so the rest of the screen picks
  /// up the fresh state. Returns the synced status (or null if the sync
  /// call failed — the periodic [adsStatusProvider] fetch and any pending
  /// webhook will still reconcile state eventually).
  Future<AdsStatusModel?> _syncAdsStatusAndRefresh() async {
    AdsStatusModel? status;
    try {
      status = await ref.read(adsRepositoryProvider).syncAdsStatus();
    } catch (_) {
      // Best-effort — see doc comment above.
    } finally {
      ref.invalidate(adsStatusProvider);
      ref.invalidate(profileNotifierProvider);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
    return status;
  }

  Future<void> _celebrateIfAdFree(
    BuildContext context,
    AppLocalizations l10n,
    AdsStatusModel? status,
  ) async {
    if (status == null || !status.isAdFree) return;
    if (!context.mounted) return;
    await _showAdFreeSuccessDialog(context, l10n);
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
            final status = await _syncAdsStatusAndRefresh();
            if (!context.mounted) return;
            await _celebrateIfAdFree(context, l10n, status);
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

  Future<void> _onRestorePressed(
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
    setState(() => _isRestoring = true);
    try {
      final restored = await revenueCatRestorePurchases();
      if (!context.mounted) return;
      if (restored) {
        final status = await _syncAdsStatusAndRefresh();
        if (!context.mounted) return;
        if (status != null && status.isAdFree) {
          await _showAdFreeSuccessDialog(context, l10n);
        } else {
          ScaffoldMessenger.maybeOf(context)?.showSnackBar(
            SnackBar(content: Text(l10n.adFreeRestorePurchasesSuccess)),
          );
        }
      } else {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(
          SnackBar(content: Text(l10n.adFreeRestorePurchasesNotFound)),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.unknownError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isRestoring = false);
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
              const SizedBox(height: 8),
              TextButton(
                onPressed: (_isLoading || _isRestoring)
                    ? null
                    : () => _onRestorePressed(context, l10n),
                child: _isRestoring
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.adFreeRestorePurchasesButton),
              ),
            ] else ...[
              Wrap(
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  _YearlySavingsBadge(
                    label: l10n.adFreeYearlySavingsBadge(
                      _yearlyPlanSavingsPercent,
                    ),
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

/// Small "Save X%" chip highlighting the yearly plan's discount versus
/// paying monthly.
class _YearlySavingsBadge extends StatelessWidget {
  const _YearlySavingsBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onTertiaryContainer,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Celebratory confirmation shown right after a purchase/restore syncs as
/// ad-free — an animated checkmark plus "You're ad-free!" copy, instead of
/// the screen silently swapping to the manage-subscription state.
Future<void> _showAdFreeSuccessDialog(
  BuildContext context,
  AppLocalizations l10n,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
            builder: (context, value, child) => Transform.scale(
              scale: value.clamp(0, 1.2),
              child: Opacity(
                opacity: value.clamp(0, 1),
                child: child,
              ),
            ),
            child: Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 64,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.adFreeSuccessTitle,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.adFreeSuccessMessage,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.doneLabel),
        ),
      ],
    ),
  );
}
