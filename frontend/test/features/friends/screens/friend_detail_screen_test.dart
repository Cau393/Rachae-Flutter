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
import 'package:frontend/core/widgets/ad_banner.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/friends/models/friend_balance_model.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friend_balance_provider.dart';
import 'package:frontend/features/friends/providers/friend_shared_expenses_provider.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/friends/screens/friend_detail_screen.dart';
import 'package:frontend/features/friends/widgets/pending_transaction_tile.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/eligible_friend_groups_provider.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/pending_transactions_provider.dart';
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

class _MockSettlementRepository extends Mock implements SettlementRepository {}

void main() {
  const friendId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const currentUid = 'cccccccc-cccc-cccc-cccc-cccccccccccc';
  const payerUid = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  late MockUser mockUser;
  late _MockSettlementRepository mockSettlement;

  FriendModel friendModel() => FriendModel.fromJson(<String, dynamic>{
    'id': friendId,
    'display_name': 'Pat Friend',
    'email': 'pat@example.com',
    'phone': null,
    'avatar_url': null,
  });

  FriendBalanceModel balanceJson(String balance) => FriendBalanceModel.fromJson(
    <String, dynamic>{'balance': balance, 'currency': 'BRL'},
  );

  Map<String, dynamic> participant(String userId, String name) =>
      <String, dynamic>{
        'user_id': userId,
        'display_name': name,
        'avatar_url': null,
      };

  TransactionModel pendingTxn(String id) =>
      TransactionModel.fromJson(<String, dynamic>{
        'id': id,
        'group_id': null,
        'payer': participant(payerUid, 'Payer'),
        'receiver': participant(currentUid, 'Me'),
        'amount': '5.00',
        'currency': 'BRL',
        'note': null,
        'is_confirmed': false,
        'is_disputed': false,
        'created_at': '2026-03-20T15:30:00Z',
      });

  List<Override> baseOverrides({
    required List<FriendModel> friends,
    required FriendBalanceModel balance,
    required List<TransactionModel> pending,
    required List<ExpenseListModel> expenses,
    List<GroupSummaryModel> eligibleGroups = const [],
  }) {
    return [
      friendsProvider.overrideWith((ref) async => friends),
      friendBalanceProvider(friendId).overrideWith((ref) async => balance),
      pendingTransactionsProvider(
        friendId,
      ).overrideWith((ref) async => pending),
      friendSharedExpensesProvider(
        friendId,
      ).overrideWith((ref) async => expenses),
      eligibleFriendGroupsProvider(
        friendId,
      ).overrideWith((ref) async => eligibleGroups),
      settlementRepositoryProvider.overrideWithValue(mockSettlement),
      authNotifierProvider.overrideWith(
        () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
      ),
    ];
  }

  void setPhysicalSize(WidgetTester tester, ui.Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  void resetPhysicalSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/friends/$friendId',
      routes: [
        GoRoute(
          path: '/friends',
          builder: (context, state) =>
              const Scaffold(body: Text('friends:list')),
        ),
        GoRoute(
          path: '/friends/:id',
          builder: (context, state) =>
              FriendDetailScreen(friendId: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/settle',
          builder: (context, state) => const SettleUpScreen(),
        ),
        GoRoute(
          path: '/expenses/:id',
          builder: (context, state) =>
              Scaffold(body: Text('expense:${state.pathParameters['id']}')),
        ),
      ],
    );
  }

  Future<void> pumpDetail(
    WidgetTester tester, {
    required GoRouter router,
    required List<Override> overrides,
    bool settle = true,
  }) async {
    setPhysicalSize(tester, const ui.Size(400, 1200));
    addTearDown(() => resetPhysicalSize(tester));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  setUp(() {
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn(currentUid);
    mockSettlement = _MockSettlementRepository();
    when(() => mockSettlement.confirmTransaction(any())).thenAnswer(
      (invocation) async =>
          pendingTxn(invocation.positionalArguments[0] as String),
    );
    when(() => mockSettlement.disputeTransaction(any())).thenAnswer(
      (invocation) async =>
          pendingTxn(invocation.positionalArguments[0] as String),
    );
  });

  testWidgets('AppBar title is friendDetailTitle', (tester) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [],
        expenses: [],
      ),
    );
    expect(find.text('Details'), findsOneWidget);
  });

  testWidgets('back button falls back to /friends when there is no stack', (
    tester,
  ) async {
    final router = buildRouter();
    await pumpDetail(
      tester,
      router: router,
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [],
        expenses: [],
      ),
    );

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.text('friends:list'), findsOneWidget);
  });

  testWidgets('loading: all providers pending shows spinner', (tester) async {
    final c1 = Completer<List<FriendModel>>();
    final c2 = Completer<FriendBalanceModel>();
    final c3 = Completer<List<TransactionModel>>();
    final c4 = Completer<List<ExpenseListModel>>();

    await pumpDetail(
      tester,
      router: buildRouter(),
      settle: false,
      overrides: [
        friendsProvider.overrideWith((ref) => c1.future),
        friendBalanceProvider(friendId).overrideWith((ref) => c2.future),
        pendingTransactionsProvider(friendId).overrideWith((ref) => c3.future),
        friendSharedExpensesProvider(friendId).overrideWith((ref) => c4.future),
        settlementRepositoryProvider.overrideWithValue(mockSettlement),
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
        ),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(PendingTransactionTile), findsNothing);
  });

  testWidgets('balance zero: friendsEven and settle button disabled', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [],
        expenses: [],
      ),
    );

    expect(find.text('Even'), findsOneWidget);
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('balance positive: friendsOwed phrasing, settle disabled', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('25.00'),
        pending: [],
        expenses: [],
      ),
    );

    expect(find.textContaining('Owes you'), findsOneWidget);
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNull);
  });

  testWidgets('balance negative: friendsOwes phrasing, settle enabled', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('-15.00'),
        pending: [],
        expenses: [],
      ),
    );

    expect(find.textContaining('Owes'), findsWidgets);
    final btn = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(btn.onPressed, isNotNull);
  });

  testWidgets('settle button navigates to /settle with query params', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('-50.00'),
        pending: [],
        expenses: [],
      ),
    );

    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();

    expect(find.text('Settle up'), findsOneWidget);
  });

  testWidgets('two pending transactions show two PendingTransactionTile', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [pendingTxn('t1'), pendingTxn('t2')],
        expenses: [],
      ),
    );

    expect(find.byType(PendingTransactionTile), findsNWidgets(2));
  });

  testWidgets('friend detail shows distinct pending and shared sections', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [pendingTxn('t1')],
        expenses: [
          ExpenseListModel.fromJson(<String, dynamic>{
            'id': 'exp-1',
            'group_id': null,
            'paid_by': <String, dynamic>{
              'id': payerUid,
              'display_name': 'Payer',
              'avatar_url': null,
            },
            'amount': '12.00',
            'currency': 'BRL',
            'amount_in_group_currency': '12.00',
            'description': 'Lunch',
            'category': 'geral',
            'expense_date': '2026-03-20',
            'split_method': 'equal',
            'split_count': 2,
            'is_deleted': false,
            'created_at': '2026-03-20T15:30:00Z',
          }),
        ],
      ),
    );

    expect(find.text('Pending settlements'), findsOneWidget);
    expect(find.text('Shared expenses'), findsOneWidget);
  });

  testWidgets('add to group button opens eligible groups sheet', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [],
        expenses: [],
        eligibleGroups: [
          GroupSummaryModel.fromJson(<String, dynamic>{
            'id': 'group-1',
            'name': 'Trip',
            'type': 'trip',
            'currency': 'BRL',
            'member_count': 2,
            'your_net_balance': '0.00',
            'created_at': '2026-03-20T15:30:00Z',
          }),
        ],
      ),
    );

    await tester.tap(find.text('Add to group'));
    await tester.pumpAndSettle();

    expect(find.text('Trip'), findsOneWidget);
  });

  testWidgets('confirm tap calls confirmTransaction', (tester) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [pendingTxn('txn-confirm-1')],
        expenses: [],
      ),
    );

    await tester.tap(find.byIcon(Icons.check_circle_outline));
    await tester.pumpAndSettle();

    verify(() => mockSettlement.confirmTransaction('txn-confirm-1')).called(1);
  });

  testWidgets('dispute flow calls disputeTransaction', (tester) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [pendingTxn('txn-dispute-1')],
        expenses: [],
      ),
    );

    await tester.tap(find.byIcon(Icons.cancel_outlined));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    verify(() => mockSettlement.disputeTransaction('txn-dispute-1')).called(1);
  });

  testWidgets('shared expenses empty shows friendDetailNoSharedExpenses', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [],
        expenses: [],
      ),
    );

    expect(find.text('No shared expenses.'), findsOneWidget);
  });

  testWidgets('no AdBanner in tree', (tester) async {
    await pumpDetail(
      tester,
      router: buildRouter(),
      overrides: baseOverrides(
        friends: [friendModel()],
        balance: balanceJson('0.00'),
        pending: [],
        expenses: [],
      ),
    );

    expect(find.byType(AdBanner), findsNothing);
  });
}
