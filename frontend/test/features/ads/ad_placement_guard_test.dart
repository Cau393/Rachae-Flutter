import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/ad_banner.dart';
import 'package:frontend/features/ads/providers/ad_service_provider.dart';
import 'package:frontend/features/ads/services/mock_ad_service.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/repositories/ads_repository.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/dashboard/screens/dashboard_screen.dart';
import 'package:frontend/features/shell/app_shell.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';
import 'package:frontend/features/expenses/screens/add_expense_screen.dart';
import 'package:frontend/features/expenses/screens/expense_detail_screen.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/group_balances_provider.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart';
import 'package:frontend/features/groups/screens/group_detail_screen.dart';
import 'package:frontend/features/groups/screens/group_list_screen.dart';
import 'package:frontend/features/friends/screens/friends_screen.dart';
import 'package:frontend/features/groups/models/group_balance_model.dart';
import 'package:frontend/features/groups/models/settlement_suggestion_model.dart';
import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/models/profile_model.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/features/notifications/providers/notifications_repository_provider.dart';
import 'package:frontend/features/profile/providers/profile_repository_provider.dart';
import 'package:frontend/features/notifications/models/notification_preference_model.dart';
import 'package:frontend/features/notifications/repositories/notifications_repository.dart';
import 'package:frontend/features/profile/repositories/profile_repository.dart';
import 'package:frontend/features/profile/screens/profile_screen.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';
import 'package:frontend/features/settlements/screens/settle_up_screen.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class MockUser extends Mock implements User {}

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

class _MockSettlementRepository extends Mock implements SettlementRepository {}

class _MockProfileRepository extends Mock implements ProfileRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockAdsRepository extends Mock implements AdsRepository {}

File _adServiceSourceFile() {
  final root = Directory.current.path.endsWith('frontend')
      ? Directory.current
      : Directory('${Directory.current.path}/frontend');
  return File('${root.path}/lib/features/ads/services/ad_service.dart');
}

List<Override> worstCaseAdsOverrides() => [
      adsStatusProvider.overrideWith(
        (ref) async => const AdsStatusModel(isAdFree: false),
      ),
      adServiceProvider.overrideWithValue(MockAdService()),
    ];

void main() {
  const expenseId = '550e8400-e29b-41d4-a716-446655440001';
  const uid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const groupId = '660e8400-e29b-41d4-a716-446655440002';

  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn(uid);
    when(() => mockUser.email).thenReturn('me@test.com');
    when(() => mockUser.userMetadata).thenReturn(null);
  });

  setUpAll(() {
    registerFallbackValue('');
  });

  ExpenseDetailModel expenseDetail() => ExpenseDetailModel.fromJson(<String, dynamic>{
        'id': expenseId,
        'group_id': groupId,
        'paid_by': <String, dynamic>{
          'id': uid,
          'display_name': 'P',
          'avatar_url': null,
        },
        'amount': '10.00',
        'currency': 'BRL',
        'exchange_rate_to_group_currency': '1.000000',
        'amount_in_group_currency': '10.00',
        'description': 'D',
        'category': 'geral',
        'expense_date': '2024-01-10',
        'split_method': 'equal',
        'splits': <dynamic>[],
        'receipt_urls': <dynamic>[],
        'created_by': <String, dynamic>{
          'id': uid,
          'display_name': 'C',
          'avatar_url': null,
        },
        'is_deleted': false,
        'deleted_at': null,
        'created_at': '2024-01-10T10:00:00.000Z',
        'updated_at': '2024-01-10T12:00:00.000Z',
      });

  GroupDetailModel groupDetail() => GroupDetailModel.fromJson(<String, dynamic>{
        'id': groupId,
        'name': 'G',
        'description': null,
        'type': 'other',
        'currency': 'BRL',
        'simplify_debts': true,
        'created_by': uid,
        'members': [
          <String, dynamic>{
            'user_id': uid,
            'display_name': 'Me',
            'avatar_url': null,
            'role': 'MEMBER',
            'joined_at': '2025-01-01T00:00:00.000Z',
            'invited_by': null,
          },
        ],
        'net_balances': <dynamic>[],
        'created_at': '2025-01-01T00:00:00.000Z',
      });

  group('Ad placement guard — forbidden screens (no ads ever)', () {
    testWidgets('ExpenseDetailScreen has no AdBanner', (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => expenseDetail(),
      );

      final router = GoRouter(
        initialLocation: '/expenses/$expenseId',
        routes: [
          GoRoute(
            path: '/expenses/:id',
            builder: (context, state) => ExpenseDetailScreen(
              expenseId: state.pathParameters['id']!,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...worstCaseAdsOverrides(),
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
            ),
            expenseRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdBanner), findsNothing);
    });

    testWidgets('AddExpenseScreen has no AdBanner', (tester) async {
      final mockRepo = _MockExpenseRepository();
      final detail = groupDetail();
      final router = GoRouter(
        initialLocation: '/expenses/new?group_id=${detail.id}',
        routes: [
          GoRoute(
            path: '/expenses/new',
            builder: (context, state) => const AddExpenseScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...worstCaseAdsOverrides(),
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
            ),
            balanceSummaryProvider.overrideWith(
              (ref) async => const BalanceSummaryModel(
                userId: uid,
                totalOwed: '0.00',
                totalOwing: '0.00',
                netBalance: '0.00',
                currency: 'BRL',
              ),
            ),
            currencyListProvider.overrideWith(
              (ref) async => [CurrencyModel.brl()],
            ),
            expenseRepositoryProvider.overrideWithValue(mockRepo),
            friendsProvider.overrideWith((ref) async => const <FriendModel>[]),
            groupDetailProvider(detail.id).overrideWith((ref) async => detail),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdBanner), findsNothing);
    });

    testWidgets('SettleUpScreen has no AdBanner', (tester) async {
      const receiverId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
      final mockSettlement = _MockSettlementRepository();
      when(
        () => mockSettlement.createTransaction(
          receiverId: any(named: 'receiverId'),
          amount: any(named: 'amount'),
          currency: any(named: 'currency'),
          groupId: any(named: 'groupId'),
          note: any(named: 'note'),
          proofUrls: any(named: 'proofUrls'),
          isOffset: any(named: 'isOffset'),
        ),
      ).thenAnswer(
        (_) async => SettlementCreateResult(
          message: 'ok',
          totalSettled: '10.00',
          transactionsCreated: [
            TransactionModel.fromJson(<String, dynamic>{
              'id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
              'group_id': null,
              'payer': <String, dynamic>{
                'user_id': uid,
                'display_name': 'Me',
                'avatar_url': null,
              },
              'receiver': <String, dynamic>{
                'user_id': receiverId,
                'display_name': 'Pat',
                'avatar_url': null,
              },
              'amount': '10.00',
              'currency': 'BRL',
              'note': null,
              'is_confirmed': false,
              'is_disputed': false,
              'created_at': '2026-03-20T15:30:00Z',
            }),
          ],
        ),
      );
      when(
        () => mockSettlement.fetchOffsetCreditPreview(
          withUserId: any(named: 'withUserId'),
          excludeGroupId: any(named: 'excludeGroupId'),
        ),
      ).thenAnswer((_) async => (credit: '0.00', currency: 'BRL'));

      final router = GoRouter(
        initialLocation: '/settle?receiver_id=$receiverId&currency=BRL',
        routes: [
          GoRoute(
            path: '/settle',
            builder: (context, state) => const SettleUpScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...worstCaseAdsOverrides(),
            friendsProvider.overrideWith(
              (ref) async => [
                FriendModel.fromJson(<String, dynamic>{
                  'id': receiverId,
                  'display_name': 'Pat',
                  'email': 'p@test.com',
                  'phone': null,
                  'avatar_url': null,
                }),
              ],
            ),
            settlementRepositoryProvider.overrideWithValue(mockSettlement),
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
            ),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AdBanner), findsNothing);
    });

    testWidgets('LoginScreen has no AdBanner', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...worstCaseAdsOverrides(),
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(const AuthState.unauthenticated()),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const LoginScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AdBanner), findsNothing);
    });

    testWidgets('ProfileScreen has no AdBanner', (tester) async {
      final profileRepo = _MockProfileRepository();
      final notifRepo = _MockNotificationsRepository();
      final adsRepo = _MockAdsRepository();
      const profile = ProfileModel(
        id: uid,
        email: 'a@b.com',
        displayName: 'A',
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
      when(() => profileRepo.fetchProfile()).thenAnswer((_) async => profile);
      when(() => profileRepo.updateProfile(any())).thenAnswer((_) async => profile);
      when(() => notifRepo.fetchPreferences()).thenAnswer((_) async => prefs);
      when(() => notifRepo.updatePreferences(any())).thenAnswer((_) async => prefs);
      when(() => adsRepo.fetchAdsStatus()).thenAnswer(
        (_) async => const AdsStatusModel(isAdFree: false),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
            ),
            profileRepositoryProvider.overrideWithValue(profileRepo),
            notificationsRepositoryProvider.overrideWithValue(notifRepo),
            adsRepositoryProvider.overrideWithValue(adsRepo),
            currencyListProvider.overrideWith(
              (ref) async => [
                CurrencyModel.brl(),
                const CurrencyModel(code: 'USD', name: 'US Dollar', symbol: r'$'),
              ],
            ),
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

      expect(find.byType(AdBanner), findsNothing);
    });
  });

  group('Ad placement guard — allowed screens (ads shown for free users)', () {
    testWidgets(
        'Dashboard route shows AdBanner under DashboardScreen when isAdFree=false',
        (tester) async {
      tester.view.physicalSize = const ui.Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const AppShell(
              currentIndex: 0,
              child: DashboardScreen(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...worstCaseAdsOverrides(),
            balanceSummaryProvider.overrideWith(
              (ref) async => const BalanceSummaryModel(
                userId: uid,
                totalOwed: '1.00',
                totalOwing: '2.00',
                netBalance: '-1.00',
                currency: 'BRL',
              ),
            ),
            activityFeedProvider.overrideWith(_EmptyActivityFeed.new),
            pendingIncomingSettlementsProvider.overrideWith(
              (ref) async => const [],
            ),
            pendingOutgoingSettlementsProvider.overrideWith(
              (ref) async => const [],
            ),
            pairwiseBalancesProvider.overrideWith((ref) async => const []),
            owedToMeExpensesProvider.overrideWith((ref) async => const []),
            groupListProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DashboardScreen),
          matching: find.byType(AdBanner),
        ),
        findsOneWidget,
      );
    });

    testWidgets('DashboardScreen has no in-body AdBanner when isAdFree=true',
        (tester) async {
      tester.view.physicalSize = const ui.Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/dashboard',
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            adsStatusProvider.overrideWith(
              (ref) async => const AdsStatusModel(isAdFree: true),
            ),
            adServiceProvider.overrideWithValue(MockAdService()),
            balanceSummaryProvider.overrideWith(
              (ref) async => const BalanceSummaryModel(
                userId: uid,
                totalOwed: '1.00',
                totalOwing: '2.00',
                netBalance: '-1.00',
                currency: 'BRL',
              ),
            ),
            activityFeedProvider.overrideWith(_EmptyActivityFeed.new),
            pendingIncomingSettlementsProvider.overrideWith(
              (ref) async => const [],
            ),
            pendingOutgoingSettlementsProvider.overrideWith(
              (ref) async => const [],
            ),
            pairwiseBalancesProvider.overrideWith((ref) async => const []),
            owedToMeExpensesProvider.overrideWith((ref) async => const []),
            groupListProvider.overrideWith((ref) async => const []),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(DashboardScreen),
          matching: find.byType(AdBanner),
        ),
        findsNothing,
      );
    });

    testWidgets('GroupListScreen has AdBanner when isAdFree=false', (tester) async {
      final group = GroupSummaryModel.fromJson({
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'name': 'Alpha',
        'type': 'home',
        'currency': 'BRL',
        'member_count': 2,
        'your_net_balance': '10.00',
        'created_at': '2025-01-01T00:00:00.000Z',
      });

      final router = GoRouter(
        initialLocation: '/groups',
        routes: [
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupListScreen(),
          ),
        ],
      );

      tester.view.physicalSize = const ui.Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...worstCaseAdsOverrides(),
            groupListProvider.overrideWith((ref) async => [group]),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(GroupListScreen),
          matching: find.byType(AdBanner),
        ),
        findsOneWidget,
      );
    });

    testWidgets('GroupDetailScreen: AdBanner in Expenses tab only', (tester) async {
      const gid = '11111111-1111-1111-1111-111111111111';
      final mockProfileRepo = _MockProfileRepository();
      when(() => mockProfileRepo.fetchProfile()).thenAnswer(
        (_) async => const ProfileModel(
          id: uid,
          email: 'me@test.com',
          displayName: 'Me',
          avatarUrl: null,
          phone: null,
          defaultCurrency: 'BRL',
          preferredLocale: 'pt_BR',
        ),
      );

      final detail = GroupDetailModel.fromJson(<String, dynamic>{
        'id': gid,
        'name': 'Trip Group',
        'description': null,
        'type': 'trip',
        'currency': 'BRL',
        'simplify_debts': true,
        'created_by': uid,
        'members': [
          <String, dynamic>{
            'user_id': uid,
            'display_name': 'Current User',
            'avatar_url': null,
            'role': 'ADMIN',
            'joined_at': '2025-03-01T09:00:00.000Z',
            'invited_by': null,
          },
        ],
        'net_balances': <dynamic>[],
        'created_at': '2025-03-01T08:00:00.000Z',
      });

      final members = detail.members;
      final mockExpenseRepo = _MockExpenseRepository();
      when(
        () => mockExpenseRepo.fetchGroupExpenses(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => []);

      final router = GoRouter(
        initialLocation: '/groups/$gid',
        routes: [
          GoRoute(
            path: '/groups/:groupId',
            builder: (context, state) => GroupDetailScreen(
              groupId: state.pathParameters['groupId']!,
            ),
          ),
        ],
      );

      tester.view.physicalSize = const ui.Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...worstCaseAdsOverrides(),
            groupDetailProvider(gid).overrideWith((ref) async => detail),
            groupMembersProvider(gid).overrideWith((ref) async => members),
            groupBalancesProvider(gid).overrideWith(
              (ref) async => (
                balances: const <GroupBalanceModel>[],
                suggestions: const <SettlementSuggestionModel>[],
                currency: 'BRL',
              ),
            ),
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
            ),
            expenseRepositoryProvider.overrideWithValue(mockExpenseRepo),
            profileRepositoryProvider.overrideWithValue(mockProfileRepo),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final ctx = tester.element(find.byType(GroupDetailScreen));
      final l10n = AppLocalizations.of(ctx)!;

      expect(
        find.descendant(
          of: find.byType(GroupDetailScreen),
          matching: find.byType(AdBanner),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text(l10n.groupDetailTabBalances));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(GroupDetailScreen),
          matching: find.byType(AdBanner),
        ),
        findsNothing,
      );

      await tester.tap(find.text(l10n.groupDetailTabMembers));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(GroupDetailScreen),
          matching: find.byType(AdBanner),
        ),
        findsNothing,
      );
    });

    testWidgets('FriendsScreen has AdBanner when isAdFree=false', (tester) async {
      final friend = FriendModel.fromJson(<String, dynamic>{
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'display_name': 'Alice',
        'email': 'a@b.com',
        'phone': null,
        'avatar_url': null,
      });

      final router = GoRouter(
        initialLocation: '/friends',
        routes: [
          GoRoute(
            path: '/friends',
            builder: (context, state) => const FriendsScreen(),
          ),
        ],
      );

      tester.view.physicalSize = const ui.Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...worstCaseAdsOverrides(),
            friendsProvider.overrideWith((ref) async => [friend]),
          ],
          child: MaterialApp.router(
            theme: AppTheme.light,
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(FriendsScreen),
          matching: find.byType(AdBanner),
        ),
        findsOneWidget,
      );
    });
  });

  group('Ad placement guard — video/interstitial never shown', () {
    test('AdService source must not declare interstitial or rewarded loaders', () {
      final file = _adServiceSourceFile();
      expect(file.existsSync(), isTrue, reason: 'ad_service.dart must exist');
      final src = file.readAsStringSync();
      expect(src.contains('loadInterstitialAd'), isFalse);
      expect(src.contains('loadRewardedAd'), isFalse);
      expect(src.contains('InterstitialAd'), isFalse);
      expect(src.contains('RewardedAd'), isFalse);
    });
  });
}

class _EmptyActivityFeed extends ActivityFeedNotifier {
  @override
  Future<List<ActivityItemModel>> build() async => const [];
}
