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
import 'package:frontend/core/widgets/ad_banner.dart' show AdBanner;
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';
import 'package:frontend/features/expenses/screens/expense_detail_screen.dart';
import 'package:frontend/features/expenses/widgets/expense_header.dart';
import 'package:frontend/features/expenses/widgets/receipt_gallery.dart';
import 'package:frontend/features/expenses/widgets/split_breakdown_list.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

const _expenseId = '550e8400-e29b-41d4-a716-446655440001';
const _uid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const _otherUserId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class MockUser extends Mock implements User {}

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

ExpenseDetailModel _expenseDetail({required String createdByUserId}) =>
    ExpenseDetailModel.fromJson(<String, dynamic>{
      'id': _expenseId,
      'group_id': '660e8400-e29b-41d4-a716-446655440002',
      'paid_by': <String, dynamic>{
        'id': _uid,
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
        'id': createdByUserId,
        'display_name': 'C',
        'avatar_url': null,
      },
      'is_deleted': false,
      'deleted_at': null,
      'created_at': '2024-01-10T10:00:00.000Z',
      'updated_at': '2024-01-10T12:00:00.000Z',
    });

void main() {
  late MockUser mockUser;

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
    when(() => mockUser.id).thenReturn(_uid);
    when(() => mockUser.email).thenReturn('me@test.com');
    when(() => mockUser.userMetadata).thenReturn(null);
  });

  setUpAll(() {
    registerFallbackValue('');
  });

  List<Override> baseOverrides(_MockExpenseRepository mockRepo) => [
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
        ),
        expenseRepositoryProvider.overrideWithValue(mockRepo),
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
          path: '/expenses/:id',
          builder: (context, state) => ExpenseDetailScreen(
            expenseId: state.pathParameters['id']!,
          ),
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
    final ctx = tester.element(find.byType(ExpenseDetailScreen));
    return AppLocalizations.of(ctx)!;
  }

  group('ExpenseDetailScreen', () {
    testWidgets('loading shows spinner without ExpenseHeader', (tester) async {
      final mockRepo = _MockExpenseRepository();
      final completer = Completer<ExpenseDetailModel>();
      when(() => mockRepo.fetchExpenseDetail(any()))
          .thenAnswer((_) => completer.future);

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ExpenseHeader), findsNothing);

      completer.complete(_expenseDetail(createdByUserId: _uid));
      await tester.pumpAndSettle();
    });

    testWidgets('loaded shows ExpenseHeader, SplitBreakdownList, ReceiptGallery',
        (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => _expenseDetail(createdByUserId: _uid),
      );

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(tester, router: router, overrides: baseOverrides(mockRepo));

      expect(find.byType(ExpenseHeader), findsOneWidget);
      expect(find.byType(SplitBreakdownList), findsOneWidget);
      expect(find.byType(ReceiptGallery), findsOneWidget);
    });

    testWidgets('close button exits to group detail when no back stack exists',
        (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => _expenseDetail(createdByUserId: _uid),
      );

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(tester, router: router, overrides: baseOverrides(mockRepo));

      final l = l10nFrom(tester);
      expect(find.byTooltip(l.closeLabel), findsOneWidget);

      await tester.tap(find.byTooltip(l.closeLabel));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/groups/660e8400-e29b-41d4-a716-446655440002');
      expect(
        find.text('GROUP_PLACEHOLDER 660e8400-e29b-41d4-a716-446655440002'),
        findsOneWidget,
      );
    });

    testWidgets('when authorized, delete IconButton is present', (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => _expenseDetail(createdByUserId: _uid),
      );

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(tester, router: router, overrides: baseOverrides(mockRepo));

      expect(find.byIcon(Icons.delete), findsOneWidget);
    });

    testWidgets('when not authorized, no delete button', (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => _expenseDetail(createdByUserId: _otherUserId),
      );

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(tester, router: router, overrides: baseOverrides(mockRepo));

      expect(find.byIcon(Icons.delete), findsNothing);
    });

    testWidgets('tapping delete shows AlertDialog with confirm text',
        (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => _expenseDetail(createdByUserId: _uid),
      );

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(tester, router: router, overrides: baseOverrides(mockRepo));

      final l = l10nFrom(tester);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      expect(find.text(l.expenseDetailDeleteConfirm), findsOneWidget);
    });

    testWidgets('confirming delete calls repository and falls back with snackbar',
        (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => _expenseDetail(createdByUserId: _uid),
      );
      when(() => mockRepo.deleteExpense(any())).thenAnswer((_) async {});

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(tester, router: router, overrides: baseOverrides(mockRepo));

      final l = l10nFrom(tester);
      await tester.tap(find.byIcon(Icons.delete));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, l.expenseDetailDeleteButton));
      await tester.pumpAndSettle();

      verify(() => mockRepo.deleteExpense(_expenseId)).called(1);
      expect(router.state.uri.path, '/groups/660e8400-e29b-41d4-a716-446655440002');
      expect(
        find.text('GROUP_PLACEHOLDER 660e8400-e29b-41d4-a716-446655440002'),
        findsOneWidget,
      );
      expect(find.text(l.expenseDetailDeleteSuccess), findsOneWidget);
    });

    testWidgets('no AdBanner in tree', (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => _expenseDetail(createdByUserId: _uid),
      );

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(tester, router: router, overrides: baseOverrides(mockRepo));

      expect(find.byType(AdBanner), findsNothing);
    });

    testWidgets('AppBar title is expenseDetailTitle', (tester) async {
      final mockRepo = _MockExpenseRepository();
      when(() => mockRepo.fetchExpenseDetail(any())).thenAnswer(
        (_) async => _expenseDetail(createdByUserId: _uid),
      );

      final router = buildRouter(initialLocation: '/expenses/$_expenseId');
      await pumpScreen(tester, router: router, overrides: baseOverrides(mockRepo));

      final l = l10nFrom(tester);
      expect(find.text(l.expenseDetailTitle), findsOneWidget);
    });
  });
}
