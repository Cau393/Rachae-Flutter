import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/models/expense_form_state.dart';
import 'package:frontend/features/expenses/widgets/split_details_panel.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  Widget app(Widget home) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );
  }

  const alice = SplitParticipant(userId: 'u1', displayName: 'Alice');
  const bob = SplitParticipant(userId: 'u2', displayName: 'Bob');

  group('SplitDetailsPanel', () {
    testWidgets(
        'equal: shows two participant names, two Chips, no TextField',
        (tester) async {
      final state = AddExpenseFormState(
        splitMethod: 'equal',
        participants: const [alice, bob],
      );
      await tester.pumpWidget(
        app(
          SplitDetailsPanel(
            state: state,
            onAmountChanged: (_, _) {},
            onShareChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(Chip), findsNWidgets(2));
    });

    testWidgets('exact: two TextField widgets', (tester) async {
      final state = AddExpenseFormState(
        splitMethod: 'exact',
        amount: '100',
        participants: const [
          SplitParticipant(
            userId: 'u1',
            displayName: 'Alice',
            amountOwed: '50',
          ),
          SplitParticipant(
            userId: 'u2',
            displayName: 'Bob',
            amountOwed: '50',
          ),
        ],
      );
      await tester.pumpWidget(
        app(
          SplitDetailsPanel(
            state: state,
            onAmountChanged: (_, _) {},
            onShareChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('percentage: TextFields and running total with %',
        (tester) async {
      final state = AddExpenseFormState(
        splitMethod: 'percentage',
        participants: const [
          SplitParticipant(
            userId: 'u1',
            displayName: 'Alice',
            shareValue: '50',
          ),
          SplitParticipant(
            userId: 'u2',
            displayName: 'Bob',
            shareValue: '50',
          ),
        ],
      );
      await tester.pumpWidget(
        app(
          SplitDetailsPanel(
            state: state,
            onAmountChanged: (_, _) {},
            onShareChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.textContaining('%'), findsWidgets);
    });

    testWidgets(
        'percentage: total line uses error color when sum is not 100',
        (tester) async {
      final state = AddExpenseFormState(
        splitMethod: 'percentage',
        participants: const [
          SplitParticipant(
            userId: 'u1',
            displayName: 'Alice',
            shareValue: '40',
          ),
          SplitParticipant(
            userId: 'u2',
            displayName: 'Bob',
            shareValue: '40',
          ),
        ],
      );
      await tester.pumpWidget(
        app(
          SplitDetailsPanel(
            state: state,
            onAmountChanged: (_, _) {},
            onShareChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pctFinder = find.textContaining('%');
      expect(pctFinder, findsWidgets);
      final theme = Theme.of(tester.element(pctFinder.first));
      final totalText = tester.widget<Text>(pctFinder.first);
      expect(totalText.style?.color, theme.colorScheme.error);
    });

    testWidgets('shares: TextFields present, no percentage total line',
        (tester) async {
      final state = AddExpenseFormState(
        splitMethod: 'shares',
        participants: const [
          SplitParticipant(
            userId: 'u1',
            displayName: 'Alice',
            shareValue: '1',
          ),
          SplitParticipant(
            userId: 'u2',
            displayName: 'Bob',
            shareValue: '1',
          ),
        ],
      );
      await tester.pumpWidget(
        app(
          SplitDetailsPanel(
            state: state,
            onAmountChanged: (_, _) {},
            onShareChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('validationError non-null: error-coloured Text', (tester) async {
      const errorMessage = 'distinctive_validation_error';
      final state = AddExpenseFormState(
        splitMethod: 'equal',
        participants: const [alice, bob],
        validationError: errorMessage,
      );
      await tester.pumpWidget(
        app(
          SplitDetailsPanel(
            state: state,
            onAmountChanged: (_, _) {},
            onShareChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final errorFinder = find.text(errorMessage);
      expect(errorFinder, findsOneWidget);
      final theme = Theme.of(tester.element(errorFinder));
      final errorText = tester.widget<Text>(errorFinder);
      expect(errorText.style?.color, theme.colorScheme.error);
    });

    testWidgets('validationError null: no error text, panel still visible',
        (tester) async {
      const errorMessage = 'distinctive_validation_error';
      final state = AddExpenseFormState(
        splitMethod: 'equal',
        participants: const [alice, bob],
        validationError: null,
      );
      await tester.pumpWidget(
        app(
          SplitDetailsPanel(
            state: state,
            onAmountChanged: (_, _) {},
            onShareChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsNothing);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
    });

    testWidgets('exact: onAmountChanged receives userId and value', (tester) async {
      final calls = <(String, String)>[];
      final state = AddExpenseFormState(
        splitMethod: 'exact',
        amount: '100',
        participants: const [
          SplitParticipant(
            userId: 'u1',
            displayName: 'Alice',
            amountOwed: '0',
          ),
          SplitParticipant(
            userId: 'u2',
            displayName: 'Bob',
            amountOwed: '0',
          ),
        ],
      );
      await tester.pumpWidget(
        app(
          SplitDetailsPanel(
            state: state,
            onAmountChanged: (userId, amount) => calls.add((userId, amount)),
            onShareChanged: (_, _) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '42');
      await tester.pumpAndSettle();

      expect(calls.isNotEmpty, isTrue);
      expect(calls.last.$1, 'u1');
      expect(calls.last.$2, '42');
    });
  });
}
