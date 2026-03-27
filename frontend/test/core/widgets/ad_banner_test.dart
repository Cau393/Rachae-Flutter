import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/ad_banner.dart';
import 'package:frontend/features/ads/providers/ad_service_provider.dart';
import 'package:frontend/features/ads/services/mock_ad_service.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  group('AdBanner', () {
    testWidgets('isAdFree false: Container height 50 under AdBanner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: false),
            ),
            adServiceProvider.overrideWithValue(MockAdService()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AdBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final containerFinder = find.descendant(
        of: find.byType(AdBanner),
        matching: find.byType(Container),
      );
      expect(containerFinder, findsOneWidget);
      expect(tester.getSize(containerFinder).height, 50.0);
      expect(
        find.byWidgetPredicate(
          (w) => '${w.runtimeType}' == 'BannerAd',
        ),
        findsNothing,
      );
    });

    testWidgets('isAdFree true: SizedBox height 0; no BannerAd in tree', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: true),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: AdBanner(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final zeroSizedBox = find.descendant(
        of: find.byType(AdBanner),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 0,
        ),
      );
      expect(zeroSizedBox, findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => '${w.runtimeType}' == 'BannerAd',
        ),
        findsNothing,
      );
    });
  });
}
