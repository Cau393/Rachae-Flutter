import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/features/notifications/models/notification_preference_model.dart';
import 'package:frontend/features/notifications/providers/notifications_repository_provider.dart';
import 'package:frontend/features/notifications/repositories/notifications_repository.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/models/profile_model.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/providers/profile_repository_provider.dart';
import 'package:frontend/features/profile/repositories/ads_repository.dart';
import 'package:frontend/features/profile/repositories/profile_repository.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/features/profile/widgets/ad_free_upgrade_card.dart';
import 'package:frontend/features/profile/widgets/legal_links_section.dart';
import 'package:frontend/features/profile/widgets/manage_subscription_button.dart';
import 'package:frontend/features/profile/widgets/notification_prefs_section.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

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
  late _MockSupabaseUser authUser;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    authUser = _MockSupabaseUser();
    when(() => authUser.id).thenReturn(
      '11111111-1111-1111-1111-111111111111',
    );
  });

  const profile = ProfileModel(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    email: 'alice@example.com',
    displayName: 'Alice',
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

  Future<void> pumpProfile(
    WidgetTester tester, {
    required List<Override> overrides,
    bool settle = true,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const ProfileScreen(),
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    }
  }

  List<Override> baseOverrides({
    required _MockProfileRepository profileRepo,
    required _MockAdsRepository adsRepo,
    required _MockNotificationsRepository notifRepo,
    Future<ProfileModel>? fetchProfileFuture,
    AdsStatusModel? adsStatus,
  }) {
    when(() => profileRepo.fetchProfile()).thenAnswer(
      (_) => fetchProfileFuture ?? Future<ProfileModel>.value(profile),
    );
    when(() => profileRepo.updateProfile(any())).thenAnswer((_) async => profile);
    when(() => adsRepo.fetchAdsStatus()).thenAnswer(
      (_) async =>
          adsStatus ?? const AdsStatusModel(isAdFree: false),
    );
    when(() => notifRepo.fetchPreferences()).thenAnswer((_) async => prefs);
    when(() => notifRepo.updatePreferences(any())).thenAnswer((_) async {});

    return [
      authNotifierProvider.overrideWith(
        () => _FakeAuthenticatedAuth(authUser),
      ),
      profileRepositoryProvider.overrideWithValue(profileRepo),
      adsRepositoryProvider.overrideWithValue(adsRepo),
      notificationsRepositoryProvider.overrideWithValue(notifRepo),
      currencyListProvider.overrideWith((ref) async {
        return [
          CurrencyModel.brl(),
          const CurrencyModel(code: 'USD', name: 'US Dollar', symbol: r'$'),
        ];
      }),
    ];
  }

  group('ProfileScreen widget', () {
    testWidgets('shows loading indicator while profile loads',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();
      final c = Completer<ProfileModel>();
      when(() => profileRepo.fetchProfile()).thenAnswer((_) => c.future);

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
          fetchProfileFuture: c.future,
        ),
        settle: false,
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
      c.complete(profile);
      await tester.pumpAndSettle();
    });

    testWidgets('shows display name from email local part when loaded',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
        ),
      );

      expect(find.text('alice'), findsOneWidget);
    });

    testWidgets('shows avatar with fallback initials when no URL',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();
      const bob = ProfileModel(
        id: 'b',
        email: 'b@b.com',
        displayName: 'Bob',
        avatarUrl: null,
        phone: null,
        defaultCurrency: 'BRL',
        preferredLocale: 'pt_BR',
      );
      when(() => profileRepo.fetchProfile()).thenAnswer((_) async => bob);
      when(() => profileRepo.updateProfile(any())).thenAnswer((_) async => bob);
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
            currencyListProvider.overrideWith((ref) async {
              return [CurrencyModel.brl()];
            }),
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

      expect(find.text('B'), findsOneWidget);
    });

    testWidgets('shows AdFreeUpgradeCard when isAdFree=false', (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
        ),
      );

      expect(find.byType(AdFreeUpgradeCard), findsOneWidget);
      expect(find.byType(ManageSubscriptionButton), findsNothing);
    });

    testWidgets('shows ManageSubscriptionButton when isAdFree=true',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();
      when(() => adsRepo.createPortalSession()).thenAnswer(
        (_) async => 'https://portal.example',
      );

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
          adsStatus: const AdsStatusModel(
            isAdFree: true,
            planType: 'monthly',
            stripePortalAvailable: true,
          ),
        ),
      );

      expect(find.byType(ManageSubscriptionButton), findsOneWidget);
      expect(find.byType(AdFreeUpgradeCard), findsNothing);
      expect(find.textContaining('Current plan'), findsOneWidget);
      expect(find.text('Manage subscription'), findsOneWidget);
    });

    testWidgets(
        'on iOS, ManageSubscription uses RevenueCat even when '
        'stripePortalAvailable is true',
        (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        final profileRepo = _MockProfileRepository();
        final adsRepo = _MockAdsRepository();
        final notifRepo = _MockNotificationsRepository();

        await pumpProfile(
          tester,
          overrides: baseOverrides(
            profileRepo: profileRepo,
            adsRepo: adsRepo,
            notifRepo: notifRepo,
            adsStatus: const AdsStatusModel(
              isAdFree: true,
              planType: 'monthly',
              stripePortalAvailable: true,
            ),
          ),
        );

        expect(find.byType(ManageSubscriptionButton), findsOneWidget);
        expect(find.text('Manage subscription'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('tapping sign out shows confirmation dialog', (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      tester.view.physicalSize = const ui.Size(400, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
        ),
      );

      await tester.ensureVisible(find.text('Sign out'));
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
    });

    testWidgets('delete account shows danger dialog', (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
        ),
      );

      await tester.ensureVisible(find.text('Delete my account'));
      await tester.tap(find.text('Delete my account'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('permanent'), findsOneWidget);
    });

    testWidgets('notification prefs section shows all five toggles',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
        ),
      );

      expect(
        find.descendant(
          of: find.byType(NotificationPrefsSection),
          matching: find.byType(SwitchListTile),
        ),
        findsNWidgets(5),
      );
    });

    testWidgets('toggling a notification pref calls updatePreferences',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
        ),
      );

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

    testWidgets('shows Terms of Use (EULA) and Privacy Policy links',
        (tester) async {
      final profileRepo = _MockProfileRepository();
      final adsRepo = _MockAdsRepository();
      final notifRepo = _MockNotificationsRepository();

      tester.view.physicalSize = const ui.Size(400, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await pumpProfile(
        tester,
        overrides: baseOverrides(
          profileRepo: profileRepo,
          adsRepo: adsRepo,
          notifRepo: notifRepo,
        ),
      );

      expect(find.byType(LegalLinksSection), findsOneWidget);
      expect(find.text('Terms of Use (EULA)'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
    });
  });
}
