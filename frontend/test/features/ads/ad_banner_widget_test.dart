import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/ad_banner.dart';
import 'package:frontend/features/ads/constants/ad_unit_ids.dart';
import 'package:frontend/features/ads/providers/ad_service_provider.dart';
import 'package:frontend/features/ads/services/ad_service.dart';
import 'package:frontend/features/ads/services/mock_ad_service.dart';
import 'package:frontend/features/ads/widgets/web_sidebar_ad.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/src/config/app_config.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  group('AdBanner widget', () {
    testWidgets('renders SizedBox.shrink when isAdFree=true', (tester) async {
      final mockService = MockAdService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: true),
            ),
            adServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AdBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AdBanner),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height != null && w.height == 0,
          ),
        ),
        findsOneWidget,
      );
      expect(mockService.loadBannerAdCallCount, 0);
    });

    testWidgets('renders SizedBox.shrink when adsStatus is loading', (
      tester,
    ) async {
      final mockService = MockAdService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) => Completer<AdsStatusModel>().future,
            ),
            adServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AdBanner()),
          ),
        ),
      );
      await tester.pump();

      expect(mockService.loadBannerAdCallCount, 0);
      expect(
        find.descendant(
          of: find.byType(AdBanner),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height != null && w.height == 0,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('calls loadBannerAd when isAdFree=false', (tester) async {
      final mockService = MockAdService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: false),
            ),
            adServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const AdBanner(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockService.loadBannerAdCallCount, 1);
      expect(mockService.lastAdUnitId, AdUnitIds.bannerForTests());
      expect(mockService.lastSize, RachaeAdSize.banner);
    });

    testWidgets('shows loading placeholder before ad loads', (tester) async {
      final mockService = MockAdService()..loadCompleter = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: false),
            ),
            adServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AdBanner()),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AdLoadingPlaceholder), findsOneWidget);
    });

    testWidgets('shows ad slot after successful load', (tester) async {
      final mockService = MockAdService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: false),
            ),
            adServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AdBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdLoadingPlaceholder), findsNothing);
      expect(
        find.descendant(
          of: find.byType(AdBanner),
          matching: find.byWidgetPredicate(
            (w) => w is SizedBox && w.height == 50,
          ),
        ),
        findsWidgets,
      );
    });

    testWidgets(
      'shows SizedBox.shrink silently on load failure — no error UI',
      (tester) async {
        final mockService = MockAdService()..failNextLoad = true;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              adsStatusProvider.overrideWith(
                (ref) async => const AdsStatusModel(isAdFree: false),
              ),
              adServiceProvider.overrideWithValue(mockService),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              locale: const Locale('pt', 'BR'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: AdBanner()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.textContaining('Error'), findsNothing);
        expect(
          find.descendant(
            of: find.byType(AdBanner),
            matching: find.byWidgetPredicate(
              (w) => w is SizedBox && w.height != null && w.height == 0,
            ),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('disposes ad handle when widget is removed from tree', (
      tester,
    ) async {
      final mockService = MockAdService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: false),
            ),
            adServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AdBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mockService.loadBannerAdCallCount, 1);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: false),
            ),
            adServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: SizedBox.shrink()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(mockService.disposeBannerAdCallCount, 1);
    });

    testWidgets('does NOT re-load ad on rebuild if adUnitId unchanged', (
      tester,
    ) async {
      final mockService = MockAdService();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: false),
            ),
            adServiceProvider.overrideWithValue(mockService),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const _RebuildTrigger(child: AdBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mockService.loadBannerAdCallCount, 1);

      final state = tester.state<_RebuildTriggerState>(
        find.byType(_RebuildTrigger),
      );
      state.rebuildParent();
      await tester.pumpAndSettle();

      expect(mockService.loadBannerAdCallCount, 1);
    });

    testWidgets(
      'on Web platform AdBanner shows WebAdsenseBanner without AdMob load',
      (tester) async {
        final mockService = MockAdService();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              adsStatusProvider.overrideWith(
                (ref) async => const AdsStatusModel(isAdFree: false),
              ),
              adServiceProvider.overrideWithValue(mockService),
            ],
            child: MaterialApp(
              theme: AppTheme.light,
              locale: const Locale('pt', 'BR'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: AdBanner()),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(WebAdsenseBanner), findsOneWidget);
        expect(mockService.loadBannerAdCallCount, 0);
        expect(find.byType(HtmlElementView), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AdBanner),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is SizedBox &&
                  w.height == AppConfig.adSenseBannerHeight &&
                  w.width == double.infinity,
            ),
          ),
          findsOneWidget,
        );
      },
      skip: !kIsWeb,
    );
  });
}

class _RebuildTrigger extends StatefulWidget {
  const _RebuildTrigger({required this.child});

  final Widget child;

  @override
  State<_RebuildTrigger> createState() => _RebuildTriggerState();
}

class _RebuildTriggerState extends State<_RebuildTrigger> {
  void rebuildParent() => setState(() {});

  @override
  Widget build(BuildContext context) => widget.child;
}
