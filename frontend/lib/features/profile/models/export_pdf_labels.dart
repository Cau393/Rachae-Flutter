import 'package:flutter/foundation.dart';

/// User-facing strings for PDF export (from ARB via [AppLocalizations]).
@immutable
class ExportPdfLabels {
  const ExportPdfLabels({
    required this.documentTitle,
    required this.emptyReportBody,
    required this.periodLine,
    required this.totalSpentLabel,
    required this.perPersonTitle,
    required this.columnPerson,
    required this.columnPaid,
    required this.columnOwed,
    required this.columnNet,
    required this.expensesTitle,
    required this.noExpenses,
    required this.expenseDescription,
    required this.expenseAmount,
    required this.expenseDate,
    required this.expenseCategory,
    required this.settlementsTitle,
    required this.noSettlements,
    required this.settlementPayer,
    required this.settlementReceiver,
    required this.settlementAmount,
    required this.settlementDate,
  });

  final String documentTitle;
  final String emptyReportBody;
  final String periodLine;
  final String totalSpentLabel;
  final String perPersonTitle;
  final String columnPerson;
  final String columnPaid;
  final String columnOwed;
  final String columnNet;
  final String expensesTitle;
  final String noExpenses;
  final String expenseDescription;
  final String expenseAmount;
  final String expenseDate;
  final String expenseCategory;
  final String settlementsTitle;
  final String noSettlements;
  final String settlementPayer;
  final String settlementReceiver;
  final String settlementAmount;
  final String settlementDate;
}
