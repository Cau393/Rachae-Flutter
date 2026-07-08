// Phase 22 Step 8 — smoke tests using integration_test binding; runnable with
// `flutter test test/integration/phase22_step8_smoke_test.dart` (flutter_tester).
// On-device: `flutter drive` expects tests under integration_test/; this project
// has no macOS target, so CI uses test/ + IntegrationTestWidgetsFlutterBinding.
// Maps to checklist in .cursor/plans/22_stripe_profile.md; Stripe and live PATCH
// remain manual.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/core/widgets/ad_banner.dart';
import 'package:frontend/features/ads/providers/ad_service_provider.dart';
import 'package:frontend/features/ads/services/mock_ad_service.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';
import 'package:frontend/features/notifications/models/notification_preference_model.dart';
import 'package:frontend/features/notifications/providers/notifications_repository_provider.dart';
import 'package:frontend/features/notifications/repositories/notifications_repository.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/models/profile_model.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/providers/export_share_pdf_provider.dart';
import 'package:frontend/features/profile/providers/profile_repository_provider.dart';
import 'package:frontend/features/profile/repositories/ads_repository.dart';
import 'package:frontend/features/profile/repositories/profile_repository.dart';
import 'package:frontend/features/profile/screens/export_screen.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/features/profile/widgets/ad_free_upgrade_card.dart';
import 'package:frontend/features/profile/widgets/manage_subscription_button.dart';
import 'package:frontend/features/profile/widgets/notification_prefs_section.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockAdsRepository extends Mock implements AdsRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockSupabaseUser extends Mock implements User {}

class _FakeAuthenticatedAuth extends AuthNotifier {
  _FakeAuthenticatedAuth(this._user);
  final User _user;

  @override
  Future<AuthState> build() async => AuthState.authenticated(user: _user);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late _MockSupabaseUser authUser;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(DateTime(2000, 1, 1));
  });

  setUp(() {
    authUser = _MockSupabaseUser();
    when(() => authUser.id).thenReturn(
      '11111111-1111-1111-1111-111111111111',
    );
  });

  const profile = ProfileModel(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    email: 'smoke@example.com',
    displayName: 'Smoke User',
    avatarUrl: null,
    phone: null,
    defaultCurrency: 'BRL',
    preferredLocale: 'pt_BR',
  );

  const prefs = NotificationPreferenceModel(
    pushExpenseCreated: true,
    pushSettlementRecorded: true,
    pushGroupInvitation: true,
    emailExpenseCreated: true,
    emailSettlementRecorded: true,
  );

  group('Phase22 Step8 smoke', () {
    testWidgets('AdBanner shrinks when adsRepository reports isAdFree',
        (tester) async {
      final adsRepo = _MockAdsRepository();
      when(() => adsRepo.fetchAdsStatus()).thenAnswer(
        (_) async => const AdsStatusModel(isAdFree: true),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsRepositoryProvider.overrideWithValue(adsRepo),
            adServiceProvider.overrideWithValue(MockAdService()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: AdBanner()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(() => adsRepo.fetchAdsStatus()).called(1);
      final zeroSizedBox = find.descendant(
        of: find.byType(AdBanner),
        matching: find.byWidgetPredicate(
          (w) => w is SizedBox && w.height == 0,
        ),
      );
      expect(zeroSizedBox, findsOneWidget);
    });

    testWidgets('ExportScreen: All groups label and Generate disabled without dates',
        (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.fetchGroups()).thenAnswer((_) async => []);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            exportSharePdfProvider.overrideWithValue((_) async {}),
            groupRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ExportScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All groups'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('ProfileScreen: AdFreeUpgradeCard monthly/yearly chips when not ad-free',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      when(() => profileRepo.fetchProfile())
          .thenAnswer((_) async => profile);
      when(() => profileRepo.updateProfile(any())).thenAnswer((_) async => profile);
      when(() => adsRepo.fetchAdsStatus()).thenAnswer(
        (_) async => const AdsStatusModel(isAdFree: false),
      );
      when(() => notifRepo.fetchPreferences()).thenAnswer((_) async => prefs);
      when(() => notifRepo.updatePreferences(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthenticatedAuth(authUser),
            ),
            profileRepositoryProvider.overrideWithValue(profileRepo),
            adsRepositoryProvider.overrideWithValue(adsRepo),
            notificationsRepositoryProvider.overrideWithValue(notifRepo),
            currencyListProvider.overrideWith((ref) async => [CurrencyModel.brl()]),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdFreeUpgradeCard), findsOneWidget);
      expect(find.text(r'Monthly (R$ 4.99)'), findsOneWidget);
      expect(find.text(r'Yearly (R$ 29.99)'), findsOneWidget);
    });

    testWidgets('ProfileScreen: ManageSubscription shows expiry when planExpiresAt set',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();
      final expires = DateTime.utc(2030, 6, 15);

      when(() => profileRepo.fetchProfile())
          .thenAnswer((_) async => profile);
      when(() => profileRepo.updateProfile(any())).thenAnswer((_) async => profile);
      when(() => adsRepo.fetchAdsStatus()).thenAnswer(
        (_) async => AdsStatusModel(
          isAdFree: true,
          planType: 'monthly',
          planExpiresAt: expires,
          stripePortalAvailable: true,
        ),
      );
      when(() => notifRepo.fetchPreferences()).thenAnswer((_) async => prefs);
      when(() => notifRepo.updatePreferences(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthenticatedAuth(authUser),
            ),
            profileRepositoryProvider.overrideWithValue(profileRepo),
            adsRepositoryProvider.overrideWithValue(adsRepo),
            notificationsRepositoryProvider.overrideWithValue(notifRepo),
            currencyListProvider.overrideWith((ref) async => [CurrencyModel.brl()]),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ManageSubscriptionButton), findsOneWidget);
      // Active (non-canceled) subscriptions show the renewal date.
      expect(find.textContaining('Renews on'), findsOneWidget);
    });

    testWidgets('ProfileScreen: notification toggle calls updatePreferences',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      when(() => profileRepo.fetchProfile())
          .thenAnswer((_) async => profile);
      when(() => profileRepo.updateProfile(any())).thenAnswer((_) async => profile);
      when(() => adsRepo.fetchAdsStatus()).thenAnswer(
        (_) async => const AdsStatusModel(isAdFree: false),
      );
      when(() => notifRepo.fetchPreferences()).thenAnswer((_) async => prefs);
      when(() => notifRepo.updatePreferences(any())).thenAnswer((_) async {});

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => _FakeAuthenticatedAuth(authUser),
            ),
            profileRepositoryProvider.overrideWithValue(profileRepo),
            adsRepositoryProvider.overrideWithValue(adsRepo),
            notificationsRepositoryProvider.overrideWithValue(notifRepo),
            currencyListProvider.overrideWith((ref) async => [CurrencyModel.brl()]),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final switches = find.descendant(
        of: find.byType(NotificationPrefsSection),
        matching: find.byType(SwitchListTile),
      );
      await tester.tap(switches.first);
      await tester.pumpAndSettle();

      verify(
        () => notifRepo.updatePreferences(<String, dynamic>{
          'push_expense_created': false,
        }),
      ).called(1);
    });
  });
}
