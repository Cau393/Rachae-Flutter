import 'dart:async';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';
import 'package:frontend/features/expenses/screens/add_expense_screen.dart';
import 'package:frontend/features/expenses/widgets/amount_field.dart';
import 'package:frontend/features/expenses/widgets/split_method_selector.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class MockUser extends Mock implements User {}

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

ExpenseDetailModel _expenseDetail(String id) =>
    ExpenseDetailModel.fromJson(<String, dynamic>{
      'id': id,
      'group_id': '660e8400-e29b-41d4-a716-446655440002',
      'paid_by': <String, dynamic>{
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
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
        'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'display_name': 'C',
        'avatar_url': null,
      },
      'is_deleted': false,
      'deleted_at': null,
      'created_at': '2024-01-10T10:00:00.000Z',
      'updated_at': '2024-01-10T10:00:00.000Z',
    });

GroupDetailModel _groupDetail() => GroupDetailModel.fromJson(<String, dynamic>{
  'id': '660e8400-e29b-41d4-a716-446655440002',
  'name': 'G',
  'description': null,
  'type': 'other',
  'currency': 'BRL',
  'simplify_debts': true,
  'created_by': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  'members': [
    <String, dynamic>{
      'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'display_name': 'Me',
      'avatar_url': null,
      'role': 'MEMBER',
      'joined_at': '2025-01-01T00:00:00.000Z',
      'invited_by': null,
    },
    <String, dynamic>{
      'user_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'display_name': 'Other',
      'avatar_url': null,
      'role': 'MEMBER',
      'joined_at': '2025-01-01T00:00:00.000Z',
      'invited_by': null,
    },
  ],
  'net_balances': <dynamic>[],
  'created_at': '2025-01-01T00:00:00.000Z',
});

FriendModel _friendModel() => FriendModel.fromJson(<String, dynamic>{
  'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  'display_name': 'Other',
  'email': 'other@example.com',
  'phone': null,
  'avatar_url': null,
});

void main() {
  const uid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  late MockUser mockUser;

  final currencies = [
    CurrencyModel.brl(),
    const CurrencyModel(code: 'USD', name: 'US Dollar', symbol: r'$'),
  ];

  void setPhysicalSize(WidgetTester tester, ui.Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  void resetPhysicalSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  setUp(() {
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn(uid);
    when(() => mockUser.email).thenReturn('me@test.com');
    when(() => mockUser.userMetadata).thenReturn(null);
  });

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  List<Override> baseOverrides(
    _MockExpenseRepository mockRepo,
    GroupDetailModel detail, {
    List<FriendModel> friends = const [],
  }) => [
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
    currencyListProvider.overrideWith((ref) async => currencies),
    expenseRepositoryProvider.overrideWithValue(mockRepo),
    friendsProvider.overrideWith((ref) async => friends),
    groupDetailProvider(detail.id).overrideWith((ref) async => detail),
  ];

  GoRouter buildRouter({required String initialLocation}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) =>
              const Scaffold(body: Text('DASHBOARD_PLACEHOLDER')),
        ),
        GoRoute(
          path: '/groups/:groupId',
          builder: (context, state) => Scaffold(
            body: Text('GROUP_PLACEHOLDER ${state.pathParameters['groupId']}'),
          ),
        ),
        GoRoute(
          path: '/expenses/new',
          builder: (context, state) => const AddExpenseScreen(),
        ),
      ],
    );
  }

  Future<void> pumpScreen(
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
          locale: const Locale('pt', 'BR'),
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

  AppLocalizations l10nFrom(WidgetTester tester) {
    final ctx = tester.element(find.byType(AddExpenseScreen));
    return AppLocalizations.of(ctx)!;
  }

  group('AddExpenseScreen', () {
    testWidgets('AppBar title is addExpenseTitle', (tester) async {
      final mockRepo = _MockExpenseRepository();
      final detail = _groupDetail();
      final router = buildRouter(
        initialLocation: '/expenses/new?group_id=${detail.id}',
      );
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo, detail),
      );

      final l = l10nFrom(tester);
      expect(find.text(l.addExpenseTitle), findsOneWidget);
    });

    testWidgets(
      'AmountField, seven CategoryChips, four split segments, save button',
      (tester) async {
        final mockRepo = _MockExpenseRepository();
        final detail = _groupDetail();
        final router = buildRouter(
          initialLocation: '/expenses/new?group_id=${detail.id}',
        );
        await pumpScreen(
          tester,
          router: router,
          overrides: baseOverrides(mockRepo, detail),
        );

        final l = l10nFrom(tester);
        expect(find.byType(AmountField), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNWidgets(7));
        expect(find.byType(SplitMethodSelector), findsOneWidget);
        expect(find.text(l.addExpenseSplitMethodEqual), findsOneWidget);
        expect(find.text(l.addExpenseSplitMethodExact), findsOneWidget);
        expect(find.text(l.addExpenseSplitMethodPercentage), findsOneWidget);
        expect(find.text(l.addExpenseSplitMethodShares), findsOneWidget);
        expect(
          find.widgetWithText(FilledButton, l.addExpenseSaveButton),
          findsOneWidget,
        );
      },
    );

    testWidgets('isSubmitting disables save and shows progress', (
      tester,
    ) async {
      final mockRepo = _MockExpenseRepository();
      final detail = _groupDetail();
      final completer = Completer<ExpenseDetailModel>();
      when(
        () => mockRepo.createExpense(any()),
      ).thenAnswer((_) => completer.future);

      final router = buildRouter(
        initialLocation: '/expenses/new?group_id=${detail.id}',
      );
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo, detail),
      );

      final l = l10nFrom(tester);
      await tester.enterText(find.byType(TextField).first, '10');
      await tester.tap(
        find.widgetWithText(FilledButton, l.addExpenseSaveButton),
      );
      await tester.pump();

      final buttonFinder = find.byType(FilledButton);
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNull);
      expect(
        find.descendant(
          of: buttonFinder,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );

      completer.complete(_expenseDetail('new-id'));
      await tester.pumpAndSettle();
    });

    testWidgets(
      'exact split mismatch shows validation message from SplitDetailsPanel',
      (tester) async {
        final mockRepo = _MockExpenseRepository();
        final detail = _groupDetail();
        final router = buildRouter(
          initialLocation: '/expenses/new?group_id=${detail.id}',
        );
        await pumpScreen(
          tester,
          router: router,
          overrides: baseOverrides(mockRepo, detail),
        );

        final l = l10nFrom(tester);
        await tester.enterText(find.byType(TextField).first, '10');
        await tester.tap(find.text(l.addExpenseSplitMethodExact));
        await tester.pumpAndSettle();

        await tester.tap(
          find.widgetWithText(FilledButton, l.addExpenseSaveButton),
        );
        await tester.pumpAndSettle();

        expect(find.text(l.addExpenseSplitDoesNotMatch), findsOneWidget);
        verifyNever(() => mockRepo.createExpense(any()));
      },
    );

    testWidgets(
      'close button exits to group detail when no back stack exists',
      (tester) async {
        final mockRepo = _MockExpenseRepository();
        final detail = _groupDetail();
        final router = buildRouter(
          initialLocation: '/expenses/new?group_id=${detail.id}',
        );
        await pumpScreen(
          tester,
          router: router,
          overrides: baseOverrides(mockRepo, detail),
        );

        final l = l10nFrom(tester);
        expect(find.byTooltip(l.closeLabel), findsOneWidget);

        await tester.tap(find.byTooltip(l.closeLabel));
        await tester.pumpAndSettle();

        expect(router.state.uri.path, '/groups/${detail.id}');
        expect(find.text('GROUP_PLACEHOLDER ${detail.id}'), findsOneWidget);
      },
    );

    testWidgets(
      'submit success falls back to group route without error snackbar',
      (tester) async {
        final mockRepo = _MockExpenseRepository();
        when(
          () => mockRepo.createExpense(any()),
        ).thenAnswer((_) async => _expenseDetail('e1'));

        final detail = _groupDetail();
        final router = buildRouter(
          initialLocation: '/expenses/new?group_id=${detail.id}',
        );
        await pumpScreen(
          tester,
          router: router,
          overrides: baseOverrides(mockRepo, detail),
        );

        final l = l10nFrom(tester);
        await tester.enterText(find.byType(TextField).first, '10');
        await tester.tap(
          find.widgetWithText(FilledButton, l.addExpenseSaveButton),
        );
        await tester.pumpAndSettle();

        expect(router.state.uri.path, '/groups/${detail.id}');
        expect(find.text('GROUP_PLACEHOLDER ${detail.id}'), findsOneWidget);
        expect(find.text(l.addExpenseError), findsNothing);
        expect(find.text(l.addExpenseSuccess), findsOneWidget);
        verify(() => mockRepo.createExpense(any())).called(1);
      },
    );

    testWidgets(
      'submit error shows addExpenseError snackbar and stays on screen',
      (tester) async {
        final mockRepo = _MockExpenseRepository();
        when(() => mockRepo.createExpense(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/expenses/'),
            type: DioExceptionType.badResponse,
          ),
        );

        final detail = _groupDetail();
        final router = buildRouter(
          initialLocation: '/expenses/new?group_id=${detail.id}',
        );
        await pumpScreen(
          tester,
          router: router,
          overrides: baseOverrides(mockRepo, detail),
        );

        final l = l10nFrom(tester);
        await tester.enterText(find.byType(TextField).first, '10');
        await tester.tap(
          find.widgetWithText(FilledButton, l.addExpenseSaveButton),
        );
        await tester.pumpAndSettle();

        expect(find.text(l.addExpenseError), findsOneWidget);
        expect(find.byType(AddExpenseScreen), findsOneWidget);
      },
    );

    testWidgets(
      'submit error with ApiException shows the backend validation message',
      (tester) async {
        final mockRepo = _MockExpenseRepository();
        when(() => mockRepo.createExpense(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/expenses/'),
            type: DioExceptionType.badResponse,
            error: const ApiException(
              statusCode: 400,
              message: '{splits: Users x do not exist.}',
            ),
          ),
        );

        final detail = _groupDetail();
        final router = buildRouter(
          initialLocation: '/expenses/new?group_id=${detail.id}',
        );
        await pumpScreen(
          tester,
          router: router,
          overrides: baseOverrides(mockRepo, detail),
        );

        final l = l10nFrom(tester);
        await tester.enterText(find.byType(TextField).first, '10');
        await tester.tap(
          find.widgetWithText(FilledButton, l.addExpenseSaveButton),
        );
        await tester.pumpAndSettle();

        expect(
          find.text('{splits: Users x do not exist.}'),
          findsOneWidget,
        );
        expect(find.text(l.addExpenseError), findsNothing);
      },
    );

    testWidgets(
      'submit timeout shows addExpenseTimeoutError snackbar and stays on screen',
      (tester) async {
        final mockRepo = _MockExpenseRepository();
        when(() => mockRepo.createExpense(any())).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/expenses/'),
            type: DioExceptionType.connectionTimeout,
          ),
        );

        final detail = _groupDetail();
        final router = buildRouter(
          initialLocation: '/expenses/new?group_id=${detail.id}',
        );
        await pumpScreen(
          tester,
          router: router,
          overrides: baseOverrides(mockRepo, detail),
        );

        final l = l10nFrom(tester);
        await tester.enterText(find.byType(TextField).first, '10');
        await tester.tap(
          find.widgetWithText(FilledButton, l.addExpenseSaveButton),
        );
        await tester.pumpAndSettle();

        expect(find.text(l.addExpenseTimeoutError), findsOneWidget);
        expect(find.byType(AddExpenseScreen), findsOneWidget);
      },
    );

    testWidgets('personal flow requires a friend before saving', (
      tester,
    ) async {
      final mockRepo = _MockExpenseRepository();
      final detail = _groupDetail();
      final router = buildRouter(initialLocation: '/expenses/new');
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo, detail, friends: [_friendModel()]),
      );

      final l = l10nFrom(tester);
      await tester.enterText(find.byType(TextField).first, '10');
      await tester.tap(
        find.widgetWithText(FilledButton, l.addExpenseSaveButton),
      );
      await tester.pumpAndSettle();

      expect(find.text(l.addExpenseFriendRequired), findsOneWidget);
      verifyNever(() => mockRepo.createExpense(any()));
    });

    testWidgets(
      'personal flow shows both users in paid by after selecting friend',
      (tester) async {
        final mockRepo = _MockExpenseRepository();
        final detail = _groupDetail();
        final router = buildRouter(initialLocation: '/expenses/new');
        await pumpScreen(
          tester,
          router: router,
          overrides: baseOverrides(mockRepo, detail, friends: [_friendModel()]),
        );

        final l = l10nFrom(tester);
        await tester.tap(find.text(l.addExpenseFriendLabel));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Other').last);
        await tester.pumpAndSettle();

        await tester.tap(find.byType(DropdownButtonFormField<String>).last);
        await tester.pumpAndSettle();

        expect(find.text('me@test.com'), findsWidgets);
        expect(find.text('Other'), findsWidgets);
      },
    );
  });
}
