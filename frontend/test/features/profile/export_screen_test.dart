import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/models/group_report_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';
import 'package:frontend/features/profile/providers/export_share_pdf_provider.dart';
import 'package:frontend/features/profile/screens/export_screen.dart';
import 'package:frontend/features/profile/widgets/export_date_range_picker.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(DateTime(2000, 1, 1));
  });

  final groupA = GroupSummaryModel.fromJson(<String, dynamic>{
    'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'name': 'Alpha',
    'type': 'home',
    'currency': 'BRL',
    'member_count': 2,
    'your_net_balance': '10.00',
    'created_at': '2025-01-01T00:00:00.000Z',
  });

  final groupB = GroupSummaryModel.fromJson(<String, dynamic>{
    'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'name': 'Beta',
    'type': 'trip',
    'currency': 'BRL',
    'member_count': 3,
    'your_net_balance': '-5.00',
    'created_at': '2025-01-02T00:00:00.000Z',
  });

  final report = GroupReportModel(
    groupId: groupA.id,
    groupName: groupA.name,
    currency: 'BRL',
    dateFrom: DateTime(2024, 1, 1),
    dateTo: DateTime(2024, 1, 31),
    totalSpent: '0',
    perPersonSpend: const [],
    expenses: const [],
    settlements: const [],
  );

  Future<void> pumpExport(
    WidgetTester tester, {
    required List<Override> overrides,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          exportSharePdfProvider.overrideWithValue((_) async {}),
          ...overrides,
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
  }

  group('ExportScreen widget', () {
    testWidgets('shows from/to date pickers', (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.fetchGroups()).thenAnswer((_) async => []);

      await pumpExport(
        tester,
        overrides: [
          groupRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      expect(find.byType(ExportDateRangePicker), findsOneWidget);
    });

    testWidgets('shows group dropdown with All Groups option', (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.fetchGroups()).thenAnswer((_) async => [groupA, groupB]);

      await pumpExport(
        tester,
        overrides: [
          groupRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      expect(find.text('All groups'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<String?>));
      await tester.pumpAndSettle();
      expect(find.text('Alpha'), findsOneWidget);
      expect(find.text('Beta'), findsOneWidget);
    });

    testWidgets('Generate button is disabled when no date range selected',
        (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.fetchGroups()).thenAnswer((_) async => []);

      await pumpExport(
        tester,
        overrides: [
          groupRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Generate button calls generateReport after dates selected',
        (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.fetchGroups()).thenAnswer((_) async => [groupA]);
      when(
        () => mockRepo.fetchGroupReport(
          groupA.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => report);

      await pumpExport(
        tester,
        overrides: [
          groupRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.tap(find.text('From date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('To date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate report'));
      await tester.pumpAndSettle();

      verify(
        () => mockRepo.fetchGroupReport(
          groupA.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).called(1);
    });

    testWidgets('shows loading indicator while generating', (tester) async {
      final mockRepo = _MockGroupRepository();
      final c = Completer<GroupReportModel>();
      when(() => mockRepo.fetchGroups()).thenAnswer((_) async => [groupA]);
      when(
        () => mockRepo.fetchGroupReport(
          groupA.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) => c.future);

      await pumpExport(
        tester,
        overrides: [
          groupRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.tap(find.text('From date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('To date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate report'));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      c.complete(report);
      await tester.pumpAndSettle();
    });

    testWidgets('shows success snackbar on completion', (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.fetchGroups()).thenAnswer((_) async => [groupA]);
      when(
        () => mockRepo.fetchGroupReport(
          groupA.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => report);

      await pumpExport(
        tester,
        overrides: [
          groupRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.tap(find.text('From date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('To date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate report'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Report generated successfully!'), findsOneWidget);
    });

    testWidgets('shows error snackbar on failure', (tester) async {
      final mockRepo = _MockGroupRepository();
      when(() => mockRepo.fetchGroups()).thenAnswer((_) async => [groupA]);
      when(
        () => mockRepo.fetchGroupReport(
          groupA.id,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenThrow(Exception('fail'));

      await pumpExport(
        tester,
        overrides: [
          groupRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );

      await tester.tap(find.text('From date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('To date'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Generate report'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('Error generating report. Try again.'),
        findsOneWidget,
      );
    });
  });
}
