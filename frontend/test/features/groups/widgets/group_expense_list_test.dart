import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/dashboard/widgets/expense_list_tile.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';
import 'package:frontend/features/groups/widgets/group_expense_list.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

ExpenseListModel _oneExpense(String id) => ExpenseListModel.fromJson(<String, dynamic>{
      'id': id,
      'group_id': '660e8400-e29b-41d4-a716-446655440002',
      'paid_by': <String, dynamic>{
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'display_name': 'Payer',
        'avatar_url': null,
      },
      'amount': '50.00',
      'currency': 'BRL',
      'amount_in_group_currency': '50.00',
      'description': 'Lunch',
      'category': 'comida',
      'expense_date': '2024-01-15',
      'split_method': 'equal',
      'split_count': 2,
      'is_deleted': false,
      'created_at': '2024-01-10T10:00:00.000Z',
    });

void main() {
  const gid = '11111111-1111-1111-1111-111111111111';

  late _MockExpenseRepository mockRepo;

  setUp(() {
    mockRepo = _MockExpenseRepository();
  });

  setUpAll(() {
    registerFallbackValue(1);
  });

  List<Override> overrides() => [
        expenseRepositoryProvider.overrideWithValue(mockRepo),
      ];

  Widget harness({String groupId = gid}) {
    return ProviderScope(
      overrides: overrides(),
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: GroupExpenseList(groupId: groupId)),
      ),
    );
  }

  group('GroupExpenseList', () {
    testWidgets('loading shows CircularProgressIndicator without ExpenseListTile',
        (tester) async {
      final completer = Completer<List<ExpenseListModel>>();
      when(
        () => mockRepo.fetchGroupExpenses(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => completer.future);

      await tester.pumpWidget(harness());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(ExpenseListTile), findsNothing);

      completer.complete(<ExpenseListModel>[]);
      await tester.pumpAndSettle();
    });

    testWidgets('empty list shows groupDetailNoExpenses', (tester) async {
      when(
        () => mockRepo.fetchGroupExpenses(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => <ExpenseListModel>[]);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupExpenseList)),
      )!;
      expect(find.text(l10n.groupDetailNoExpenses), findsOneWidget);
    });

    testWidgets('one expense shows ExpenseListTile with description', (tester) async {
      when(
        () => mockRepo.fetchGroupExpenses(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => [_oneExpense('exp-1')]);

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      expect(find.byType(ExpenseListTile), findsOneWidget);
      expect(find.text('Lunch'), findsOneWidget);
    });

    testWidgets('error shows retry', (tester) async {
      when(
        () => mockRepo.fetchGroupExpenses(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(Exception('network'));

      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(GroupExpenseList)),
      )!;
      expect(find.text(l10n.errorGeneric), findsOneWidget);
      expect(find.text(l10n.retryLabel), findsOneWidget);
    });
  });
}
