// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/groups/models/group_report_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/groups/repositories/group_repository.dart';
import 'package:frontend/features/profile/models/export_pdf_labels.dart';
import 'package:frontend/features/profile/providers/export_notifier.dart';

class _MockGroupRepository extends Mock implements GroupRepository {}

const _testPdfLabels = ExportPdfLabels(
  documentTitle: 'Doc',
  emptyReportBody: 'Empty',
  periodLine: 'Period',
  totalSpentLabel: 'Total',
  perPersonTitle: 'Per person',
  columnPerson: 'Person',
  columnPaid: 'Paid',
  columnOwed: 'Owed',
  columnNet: 'Net',
  expensesTitle: 'Expenses',
  noExpenses: 'No expenses',
  expenseDescription: 'Desc',
  expenseAmount: 'Amt',
  expenseDate: 'Date',
  expenseCategory: 'Cat',
  settlementsTitle: 'Settlements',
  noSettlements: 'No settlements',
  settlementPayer: 'Payer',
  settlementReceiver: 'Receiver',
  settlementAmount: 'Amount',
  settlementDate: 'Date',
);

void main() {
  late _MockGroupRepository mockRepo;
  late ProviderContainer container;

  final report = GroupReportModel(
    groupId: '660e8400-e29b-41d4-a716-446655440002',
    groupName: 'Trip',
    currency: 'BRL',
    dateFrom: DateTime(2024, 1, 1),
    dateTo: DateTime(2024, 1, 31),
    totalSpent: '100.00',
    perPersonSpend: const [],
    expenses: const [],
    settlements: const [],
  );

  final from = DateTime(2024, 1, 1);
  final to = DateTime(2024, 1, 31);

  setUp(() {
    mockRepo = _MockGroupRepository();
    container = ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    // Keep autoDispose provider alive across async gaps in tests.
    container.listen(exportNotifierProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  setUpAll(() {
    registerFallbackValue(DateTime(2000));
  });

  group('ExportNotifier', () {
    test('initial state is null (no export in progress)', () async {
      final value = await container.read(exportNotifierProvider.future);
      expect(value, isNull);
    });

    test('generateReport sets isGenerating = true during fetch', () async {
      final c = Completer<GroupReportModel>();
      when(
        () => mockRepo.fetchGroupReport(
          any(),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) => c.future);

      final future =
          container.read(exportNotifierProvider.notifier).generateReport(
                groupId: report.groupId,
                from: from,
                to: to,
                pdfLabels: _testPdfLabels,
              );

      await Future<void>.delayed(Duration.zero);
      expect(
        container.read(exportNotifierProvider).value?.isGenerating,
        isTrue,
      );

      c.complete(report);
      await future;
    });

    test('generateReport fetches group report from API', () async {
      when(
        () => mockRepo.fetchGroupReport(
          report.groupId,
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => report);

      await container.read(exportNotifierProvider.notifier).generateReport(
            groupId: report.groupId,
            from: from,
            to: to,
            pdfLabels: _testPdfLabels,
          );

      verify(
        () => mockRepo.fetchGroupReport(
          report.groupId,
          from: from,
          to: to,
        ),
      ).called(1);
    });

    test('generateReport creates PDF bytes from report data', () async {
      when(
        () => mockRepo.fetchGroupReport(
          any(),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenAnswer((_) async => report);

      await container.read(exportNotifierProvider.notifier).generateReport(
            groupId: report.groupId,
            from: from,
            to: to,
            pdfLabels: _testPdfLabels,
          );

      expect(
        container.read(exportNotifierProvider).value?.pdfBytes,
        isNotNull,
      );
    });

    test('generateReport sets error state on failure', () async {
      when(
        () => mockRepo.fetchGroupReport(
          any(),
          from: any(named: 'from'),
          to: any(named: 'to'),
        ),
      ).thenThrow(Exception('boom'));

      await container.read(exportNotifierProvider.notifier).generateReport(
            groupId: report.groupId,
            from: from,
            to: to,
            pdfLabels: _testPdfLabels,
          );

      expect(
        container.read(exportNotifierProvider).value?.error,
        isNotNull,
      );
    });
  });
}
