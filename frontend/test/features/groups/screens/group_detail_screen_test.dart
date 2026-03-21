import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/ad_banner.dart' show AdBanner, AdStatus, adStatusProvider;
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/repositories/dashboard_repository.dart';
import 'package:frontend/features/groups/models/group_balance_model.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/models/settlement_suggestion_model.dart';
import 'package:frontend/features/groups/providers/group_balances_provider.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_members_provider.dart';
import 'package:frontend/features/groups/screens/group_detail_screen.dart';
import 'package:frontend/features/groups/widgets/group_expense_list.dart';
import 'package:frontend/features/groups/widgets/group_header.dart';
import 'package:frontend/features/groups/widgets/member_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class MockUser extends Mock implements User {}

class _MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  const gid = '11111111-1111-1111-1111-111111111111';
  const adminUid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const memberUid = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  late MockUser mockUser;
  late _MockDashboardRepository mockDashboard;

  GroupDetailModel detailForRole(String currentUid, String currentRole) {
    return GroupDetailModel.fromJson(<String, dynamic>{
      'id': gid,
      'name': 'Trip Group',
      'description': null,
      'type': 'trip',
      'currency': 'BRL',
      'simplify_debts': true,
      'created_by': adminUid,
      'members': [
        <String, dynamic>{
          'user_id': currentUid,
          'display_name': 'Current User',
          'avatar_url': null,
          'role': currentRole,
          'joined_at': '2025-03-01T09:00:00.000Z',
          'invited_by': null,
        },
        <String, dynamic>{
          'user_id': memberUid,
          'display_name': 'Other',
          'avatar_url': null,
          'role': 'MEMBER',
          'joined_at': '2025-03-01T09:00:00.000Z',
          'invited_by': null,
        },
      ],
      'net_balances': <dynamic>[],
      'created_at': '2025-03-01T08:00:00.000Z',
    });
  }

  void setPhysicalSize(WidgetTester tester, ui.Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  void resetPhysicalSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  List<Override> baseOverrides({
    required GroupDetailModel detail,
    required List<GroupMemberModel> members,
    required AuthState authState,
  }) {
    return [
      groupDetailProvider(gid).overrideWith((ref) async => detail),
      groupMembersProvider(gid).overrideWith((ref) async => members),
      groupBalancesProvider(gid).overrideWith(
        (ref) async => (
          balances: const <GroupBalanceModel>[],
          suggestions: const <SettlementSuggestionModel>[],
          currency: 'BRL',
        ),
      ),
      authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
      dashboardRepositoryProvider.overrideWithValue(mockDashboard),
      adStatusProvider.overrideWithValue(const AdStatus(isAdFree: false)),
    ];
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/groups/$gid',
      routes: [
        GoRoute(
          path: '/groups/:groupId',
          builder: (context, state) => GroupDetailScreen(
            groupId: state.pathParameters['groupId']!,
          ),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (_, _) => const Scaffold(body: Text('settings_screen')),
            ),
          ],
        ),
        GoRoute(
          path: '/expenses/new',
          builder: (_, state) => Scaffold(
            body: Text('new_expense ${state.uri.query}'),
          ),
        ),
      ],
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required GoRouter router,
    required List<Override> overrides,
  }) async {
    setPhysicalSize(tester, const ui.Size(400, 900));
    addTearDown(() => resetPhysicalSize(tester));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
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
  }

  setUp(() {
    mockUser = MockUser();
    mockDashboard = _MockDashboardRepository();
    when(() => mockUser.id).thenReturn(adminUid);
    when(
      () => mockDashboard.fetchActivity(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        groupId: any(named: 'groupId'),
      ),
    ).thenAnswer((_) async => []);
  });

  group('GroupDetailScreen', () {
    testWidgets('default tab is Expenses: GroupExpenseList and AdBanner',
        (tester) async {
      final detail = detailForRole(adminUid, 'ADMIN');
      final router = buildRouter();
      await pumpDetail(
        tester,
        router: router,
        overrides: baseOverrides(
          detail: detail,
          members: detail.members,
          authState: AuthState.authenticated(user: mockUser),
        ),
      );

      expect(find.byType(GroupExpenseList), findsOneWidget);
      expect(find.byType(AdBanner), findsOneWidget);
    });

    testWidgets('loading shows spinner in body', (tester) async {
      final completer = Completer<GroupDetailModel>();
      final router = buildRouter();
      setPhysicalSize(tester, const ui.Size(400, 900));
      addTearDown(() => resetPhysicalSize(tester));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            groupDetailProvider(gid).overrideWith((ref) => completer.future),
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
            ),
            dashboardRepositoryProvider.overrideWithValue(mockDashboard),
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
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      completer.complete(detailForRole(adminUid, 'ADMIN'));
      await tester.pumpAndSettle();
    });

    testWidgets('GroupHeader is above TabBar vertically', (tester) async {
      final detail = detailForRole(adminUid, 'ADMIN');
      final router = buildRouter();
      await pumpDetail(
        tester,
        router: router,
        overrides: baseOverrides(
          detail: detail,
          members: detail.members,
          authState: AuthState.authenticated(user: mockUser),
        ),
      );

      final headerRect = tester.getRect(find.byType(GroupHeader));
      final tabBarRect = tester.getRect(find.byType(TabBar));
      expect(headerRect.top, lessThan(tabBarRect.top));
    });

    testWidgets('Members tab shows one MemberListTile per member',
        (tester) async {
      final detail = detailForRole(adminUid, 'ADMIN');
      final router = buildRouter();
      await pumpDetail(
        tester,
        router: router,
        overrides: baseOverrides(
          detail: detail,
          members: detail.members,
          authState: AuthState.authenticated(user: mockUser),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupDetailScreen)),
      )!;
      await tester.tap(find.text(l10n.groupDetailTabMembers));
      await tester.pumpAndSettle();

      expect(find.byType(MemberListTile), findsNWidgets(detail.members.length));
    });

    testWidgets('ADMIN sees settings IconButton', (tester) async {
      when(() => mockUser.id).thenReturn(adminUid);
      final detail = detailForRole(adminUid, 'ADMIN');
      final router = buildRouter();
      await pumpDetail(
        tester,
        router: router,
        overrides: baseOverrides(
          detail: detail,
          members: detail.members,
          authState: AuthState.authenticated(user: mockUser),
        ),
      );

      expect(find.byIcon(Icons.settings), findsOneWidget);
    });

    testWidgets('MEMBER does not see settings IconButton', (tester) async {
      when(() => mockUser.id).thenReturn(memberUid);
      final detail = detailForRole(memberUid, 'MEMBER');
      final router = buildRouter();
      await pumpDetail(
        tester,
        router: router,
        overrides: baseOverrides(
          detail: detail,
          members: detail.members,
          authState: AuthState.authenticated(user: mockUser),
        ),
      );

      expect(find.byIcon(Icons.settings), findsNothing);
    });

    testWidgets('Expenses FAB navigates to /expenses/new with group_id',
        (tester) async {
      final detail = detailForRole(adminUid, 'ADMIN');
      final router = buildRouter();
      await pumpDetail(
        tester,
        router: router,
        overrides: baseOverrides(
          detail: detail,
          members: detail.members,
          authState: AuthState.authenticated(user: mockUser),
        ),
      );

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/expenses/new');
      expect(router.state.uri.queryParameters['group_id'], gid);
    });

    testWidgets('Members tab: MEMBER has no FAB', (tester) async {
      when(() => mockUser.id).thenReturn(memberUid);
      final detail = detailForRole(memberUid, 'MEMBER');
      final router = buildRouter();
      await pumpDetail(
        tester,
        router: router,
        overrides: baseOverrides(
          detail: detail,
          members: detail.members,
          authState: AuthState.authenticated(user: mockUser),
        ),
      );

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupDetailScreen)),
      )!;
      await tester.tap(find.text(l10n.groupDetailTabMembers));
      await tester.pumpAndSettle();

      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('AdBanner on Expenses only; absent on Balances and Members',
        (tester) async {
      final detail = detailForRole(adminUid, 'ADMIN');
      final router = buildRouter();
      await pumpDetail(
        tester,
        router: router,
        overrides: baseOverrides(
          detail: detail,
          members: detail.members,
          authState: AuthState.authenticated(user: mockUser),
        ),
      );

      expect(find.byType(AdBanner), findsOneWidget);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupDetailScreen)),
      )!;
      await tester.tap(find.text(l10n.groupDetailTabBalances));
      await tester.pumpAndSettle();
      expect(find.byType(AdBanner), findsNothing);

      await tester.tap(find.text(l10n.groupDetailTabMembers));
      await tester.pumpAndSettle();
      expect(find.byType(AdBanner), findsNothing);
    });
  });
}
