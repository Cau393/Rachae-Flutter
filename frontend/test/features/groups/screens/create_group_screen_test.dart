import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';
import 'package:frontend/features/groups/screens/create_group_screen.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

GroupDetailModel _newGroup(String id) => GroupDetailModel.fromJson({
      'id': id,
      'name': 'New',
      'description': null,
      'type': 'other',
      'currency': 'BRL',
      'simplify_debts': true,
      'created_by': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'members': <dynamic>[],
      'net_balances': <dynamic>[],
      'created_at': '2025-01-01T00:00:00.000Z',
    });

void main() {
  const newId = '99999999-9999-9999-9999-999999999999';

  final currencies = [
    CurrencyModel.brl(),
    const CurrencyModel(code: 'USD', name: 'US Dollar', symbol: r'$'),
  ];

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  void setPhysicalSize(WidgetTester tester, ui.Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  void resetPhysicalSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  List<Override> baseOverrides(_MockGroupRepository mockRepo) => [
        groupRepositoryProvider.overrideWithValue(mockRepo),
        groupListProvider.overrideWith((ref) async => const <GroupSummaryModel>[]),
        currencyListProvider.overrideWith((ref) async => currencies),
      ];

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/groups/new',
      routes: [
        GoRoute(
          path: '/groups',
          builder: (context, state) =>
              const Scaffold(body: Text('groups_list_placeholder')),
          routes: [
            GoRoute(
              path: 'new',
              builder: (context, state) => const CreateGroupScreen(),
            ),
            GoRoute(
              path: ':groupId',
              builder: (context, state) => Scaffold(
                body: Text('detail_${state.pathParameters['groupId']}'),
              ),
            ),
          ],
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
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  AppLocalizations l10n(WidgetTester tester) {
    final ctx = tester.element(find.byType(CreateGroupScreen));
    return AppLocalizations.of(ctx)!;
  }

  group('CreateGroupScreen', () {
    testWidgets('submitting with empty name shows requiredFieldError', (tester) async {
      final mockRepo = _MockGroupRepository();
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
      );

      final l = l10n(tester);
      await tester.tap(find.text(l.createGroupButton));
      await tester.pumpAndSettle();

      expect(find.text(l.requiredFieldError), findsOneWidget);
      verifyNever(() => mockRepo.createGroup(any()));
    });

    testWidgets('valid form submission calls createGroup once with expected fields',
        (tester) async {
      final mockRepo = _MockGroupRepository();
      Map<String, dynamic>? captured;
      when(() => mockRepo.createGroup(any())).thenAnswer((invocation) async {
        captured = Map<String, dynamic>.from(
          invocation.positionalArguments.first! as Map<String, dynamic>,
        );
        return _newGroup(newId);
      });

      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
      );

      final l = l10n(tester);
      await tester.enterText(find.byType(TextFormField).first, '  Casa  ');
      await tester.tap(find.text(l.createGroupButton));
      await tester.pumpAndSettle();

      verify(() => mockRepo.createGroup(any())).called(1);
      expect(captured, isNotNull);
      expect(captured!['name'], 'Casa');
      expect(captured!['type'], 'other');
      expect(captured!['currency'], 'BRL');
      expect(captured!['simplify_debts'], isTrue);
      expect(captured!['member_ids'], isEmpty);
    });

    testWidgets('loading state disables submit and shows progress indicator',
        (tester) async {
      final mockRepo = _MockGroupRepository();
      final completer = Completer<GroupDetailModel>();
      when(() => mockRepo.createGroup(any())).thenAnswer((_) => completer.future);

      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
      );

      final l = l10n(tester);
      await tester.enterText(find.byType(TextFormField).first, 'G');
      await tester.tap(find.text(l.createGroupButton));
      await tester.pump();

      final buttonFinder = find.widgetWithText(FilledButton, l.createGroupButton);
      final button = tester.widget<FilledButton>(buttonFinder);
      expect(button.onPressed, isNull);
      expect(
        find.descendant(of: buttonFinder, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );

      completer.complete(_newGroup(newId));
      await tester.pumpAndSettle();
    });

    testWidgets('AsyncError shows createGroupError snackbar', (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.createGroup(any())).thenThrow(Exception('network'));

      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
      );

      final l = l10n(tester);
      await tester.enterText(find.byType(TextFormField).first, 'G');
      await tester.tap(find.text(l.createGroupButton));
      await tester.pumpAndSettle();

      expect(find.text(l.createGroupError), findsOneWidget);
    });

    testWidgets('success shows snackbar and navigates to /groups/{id}', (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.createGroup(any())).thenAnswer((_) async => _newGroup(newId));

      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
      );

      final l = l10n(tester);
      await tester.enterText(find.byType(TextFormField).first, 'G');
      await tester.tap(find.text(l.createGroupButton));
      await tester.pumpAndSettle();

      expect(find.text(l.createGroupSuccess), findsOneWidget);
      expect(router.state.uri.path, '/groups/$newId');
    });

    testWidgets('currency dropdown shows menu items when list is mocked', (tester) async {
      final mockRepo = _MockGroupRepository();
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
      );

      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('BRL'), findsWidgets);
      expect(find.textContaining('USD'), findsWidgets);
    });

    testWidgets('simplify debts switch defaults to true', (tester) async {
      final mockRepo = _MockGroupRepository();
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
      );

      final l = l10n(tester);
      final tileFinder = find.ancestor(
        of: find.text(l.createGroupSimplifyDebts),
        matching: find.byType(SwitchListTile),
      );
      final tile = tester.widget<SwitchListTile>(tileFinder);
      expect(tile.value, isTrue);
    });

    testWidgets('shows localized AppBar title', (tester) async {
      final mockRepo = _MockGroupRepository();
      final router = buildRouter();
      await pumpScreen(
        tester,
        router: router,
        overrides: baseOverrides(mockRepo),
      );

      final l = l10n(tester);
      expect(find.text(l.createGroupTitle), findsOneWidget);
    });
  });
}
