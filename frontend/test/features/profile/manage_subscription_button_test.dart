import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/repositories/ads_repository.dart';
import 'package:frontend/features/profile/widgets/manage_subscription_button.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class _MockAdsRepository extends Mock implements AdsRepository {}

void main() {
  late _MockAdsRepository adsRepo;

  setUp(() {
    adsRepo = _MockAdsRepository();
  });

  Future<void> pumpButton(WidgetTester tester, AdsStatusModel model) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adsRepositoryProvider.overrideWithValue(adsRepo),
        ],
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: ManageSubscriptionButton(model: model)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('ManageSubscriptionButton — App Store subscriptions without a '
      'Stripe portal', () {
    testWidgets(
        'shows a Manage subscription button that links to Apple '
        'when stripePortalAvailable is false and not on native iOS',
        (tester) async {
      const model = AdsStatusModel(
        isAdFree: true,
        planType: 'monthly',
        stripePortalAvailable: false,
      );

      await pumpButton(tester, model);

      expect(find.text('Manage subscription'), findsOneWidget);
      expect(
        find.text('Subscription changes are not available in the app. '
            'Contact support if you need help.'),
        findsNothing,
      );
    });

    testWidgets(
        'shows the Stripe portal button (not the Apple fallback) when '
        'stripePortalAvailable is true', (tester) async {
      const model = AdsStatusModel(
        isAdFree: true,
        planType: 'monthly',
        stripePortalAvailable: true,
      );

      await pumpButton(tester, model);

      // stripePortalAvailable true (and not iOS) => Stripe portal button,
      // not the Apple fallback or the "managed elsewhere" text.
      expect(find.text('Manage subscription'), findsOneWidget);
      expect(
        find.textContaining('Use Manage subscription to change your plan'),
        findsOneWidget,
      );
    });
  });
}
