import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/ads/constants/ad_unit_ids.dart';
import 'package:frontend/features/ads/providers/ad_service_provider.dart';
import 'package:frontend/features/ads/services/ad_service.dart';
import 'package:frontend/features/ads/widgets/web_sidebar_ad.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/src/config/app_config.dart';

/// Shown under the ad banner while [AdService.loadBannerAd] is in flight.
class AdLoadingPlaceholder extends StatelessWidget {
  const AdLoadingPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }
}

/// AdMob banner for allowed screens. Uses [adsStatusProvider] and [adServiceProvider] only.
class AdBanner extends ConsumerStatefulWidget {
  const AdBanner({super.key, this.adUnitId});

  /// When null, [AdUnitIds.banner] is used.
  final String? adUnitId;

  @override
  ConsumerState<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends ConsumerState<AdBanner> {
  AdHandle? _handle;
  bool _loadStarted = false;
  bool _loadFailed = false;
  AdService? _adServiceUsed;
  bool _adFreeCleanupScheduled = false;

  String get _effectiveUnitId => widget.adUnitId ?? AdUnitIds.banner;

  @override
  void dispose() {
    final h = _handle;
    final svc = _adServiceUsed;
    _handle = null;
    _adServiceUsed = null;
    if (h != null) {
      svc?.disposeBannerAd(h);
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(AdBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.adUnitId != widget.adUnitId) {
      final h = _handle;
      final svc = _adServiceUsed;
      if (h != null) {
        svc?.disposeBannerAd(h);
      }
      setState(() {
        _handle = null;
        _loadStarted = false;
        _loadFailed = false;
        _adServiceUsed = null;
      });
    }
  }

  void _scheduleAdFreeCleanup() {
    if (_handle == null || _adFreeCleanupScheduled) return;
    _adFreeCleanupScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _adFreeCleanupScheduled = false;
      if (!mounted) return;
      final ads = ref.read(adsStatusProvider);
      if (!ads.hasValue || !ads.requireValue.isAdFree) return;
      final h = _handle;
      if (h == null) return;
      final svc = _adServiceUsed;
      setState(() {
        _handle = null;
        _loadStarted = false;
        _loadFailed = false;
      });
      svc?.disposeBannerAd(h);
    });
  }

  void _startLoadOnce() {
    if (!mounted || kIsWeb) return;
    final ads = ref.read(adsStatusProvider);
    if (!ads.hasValue || ads.requireValue.isAdFree) return;
    if (_loadStarted) return;

    _loadStarted = true;
    final service = ref.read(adServiceProvider);
    _adServiceUsed = service;
    service
        .loadBannerAd(
          adUnitId: _effectiveUnitId,
          size: RachaeAdSize.banner,
          onLoaded: (AdHandle handle) {
            if (!mounted) {
              service.disposeBannerAd(handle);
              return;
            }
            final stillAds =
                ref.read(adsStatusProvider).hasValue &&
                !ref.read(adsStatusProvider).requireValue.isAdFree;
            if (!stillAds) {
              service.disposeBannerAd(handle);
              return;
            }
            setState(() => _handle = handle);
          },
          onFailed: (String code, String message) {
            if (!mounted) return;
            setState(() {
              _loadFailed = true;
            });
          },
        )
        .then((_) {
          if (mounted) setState(() {});
        });
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(adsStatusProvider);

    return adsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (AdsStatusModel status) {
        if (status.isAdFree) {
          _scheduleAdFreeCleanup();
          return const SizedBox.shrink();
        }

        // Web: AdSense auto unit in the same horizontal strip as the native banner.
        if (kIsWeb) {
          return WebAdsenseBanner(
            client: AppConfig.adSenseClient,
            slot: AppConfig.adSenseSlot,
            height: AppConfig.adSenseBannerHeight,
          );
        }

        if (_loadFailed) {
          return const SizedBox.shrink();
        }

        if (_handle != null) {
          return SizedBox(
            height: 50,
            width: double.infinity,
            child: _handle!.adWidget,
          );
        }

        if (!_loadStarted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _startLoadOnce());
        }
        return const AdLoadingPlaceholder();
      },
    );
  }
}
