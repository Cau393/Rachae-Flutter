import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/repositories/ads_repository.dart';
import 'package:frontend/features/profile/widgets/ad_free_upgrade_card.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class _MockAdsRepository extends Mock implements AdsRepository {}

void main() {
  late _MockAdsRepository adsRepo;

  setUp(() {
    adsRepo = _MockAdsRepository();
  });

  Future<void> pumpCard(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adsRepositoryProvider.overrideWithValue(adsRepo),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: AdFreeUpgradeCard()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('AdFreeUpgradeCard — Stripe/web plan selector', () {
    testWidgets('shows monthly and yearly plan chips with a savings badge '
        'on the yearly option', (tester) async {
      await pumpCard(tester);

      expect(find.byType(ChoiceChip), findsNWidgets(2));
      // The static "Save X%" badge should always render next to the plan
      // chips on the Stripe/web path.
      expect(find.textContaining('Save'), findsOneWidget);
    });

    testWidgets('does not show the restore purchases button on the '
        'Stripe/web path', (tester) async {
      await pumpCard(tester);

      expect(find.text('Restore purchases'), findsNothing);
    });

    testWidgets('selecting the yearly plan updates chip selection',
        (tester) async {
      await pumpCard(tester);

      final yearlyChip = find.widgetWithText(ChoiceChip, 'Yearly (R\$ 29.99)');
      expect(yearlyChip, findsOneWidget);
      await tester.tap(yearlyChip);
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(yearlyChip);
      expect(chip.selected, isTrue);
    });
  });

  group('AdFreeUpgradeCard — RevenueCat native iOS path', () {
    testWidgets('shows a restore purchases button', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await pumpCard(tester);

        expect(find.text('Restore purchases'), findsOneWidget);
        // The plan-selector chips (Stripe/web only) should not render.
        expect(find.byType(ChoiceChip), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
