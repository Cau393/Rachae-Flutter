import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:frontend/features/groups/models/group_report_model.dart';
import 'package:frontend/features/profile/models/export_pdf_labels.dart';

/// Builds a multi-group PDF from API-shaped [GroupReportModel] data.
Future<Uint8List> buildExportPdf(
  List<GroupReportModel> reports,
  ExportPdfLabels labels,
) async {
  final doc = pw.Document();

  if (reports.isEmpty) {
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) => pw.Center(
          child: pw.Text(labels.emptyReportBody),
        ),
      ),
    );
    return doc.save();
  }

  for (final report in reports) {
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              labels.documentTitle,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            report.groupName,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(labels.periodLine),
          pw.SizedBox(height: 4),
          pw.Text(
            '${labels.totalSpentLabel}: ${report.totalSpent} ${report.currency}',
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            labels.perPersonTitle,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey400),
            children: [
              pw.TableRow(
                children: [
                  _cell(labels.columnPerson, header: true),
                  _cell(labels.columnPaid, header: true),
                  _cell(labels.columnOwed, header: true),
                  _cell(labels.columnNet, header: true),
                ],
              ),
              ...report.perPersonSpend.map(
                (p) => pw.TableRow(
                  children: [
                    _cell(p.displayName),
                    _cell(p.totalPaid),
                    _cell(p.totalOwed),
                    _cell(p.net),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            labels.expensesTitle,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (report.expenses.isEmpty)
            pw.Text(labels.noExpenses)
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  children: [
                    _cell(labels.expenseDescription, header: true),
                    _cell(labels.expenseAmount, header: true),
                    _cell(labels.expenseDate, header: true),
                    _cell(labels.expenseCategory, header: true),
                  ],
                ),
                ...report.expenses.map(_expenseRow),
              ],
            ),
          pw.SizedBox(height: 16),
          pw.Text(
            labels.settlementsTitle,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          if (report.settlements.isEmpty)
            pw.Text(labels.noSettlements)
          else
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  children: [
                    _cell(labels.settlementPayer, header: true),
                    _cell(labels.settlementReceiver, header: true),
                    _cell(labels.settlementAmount, header: true),
                    _cell(labels.settlementDate, header: true),
                  ],
                ),
                ...report.settlements.map(_settlementRow),
              ],
            ),
        ],
      ),
    );
  }

  return doc.save();
}

pw.TableRow _expenseRow(Map<String, dynamic> e) {
  return pw.TableRow(
    children: [
      _cell(_expenseField(e, 'description', 'title', 'note')),
      _cell(_expenseField(e, 'amount_in_group_currency', 'amount', 'total')),
      _cell(_expenseField(e, 'expense_date', 'date', 'created_at')),
      _cell(_expenseField(e, 'category', 'category_slug')),
    ],
  );
}

pw.TableRow _settlementRow(Map<String, dynamic> s) {
  final payer = s['payer__display_name']?.toString() ?? '';
  final receiver = s['receiver__display_name']?.toString() ?? '';
  final amount = s['amount']?.toString() ?? '';
  final cur = s['currency']?.toString() ?? '';
  final amtLine = cur.isNotEmpty ? '$amount $cur' : amount;
  final created = s['created_at']?.toString() ?? '';
  return pw.TableRow(
    children: [
      _cell(payer),
      _cell(receiver),
      _cell(amtLine),
      _cell(created),
    ],
  );
}

pw.Widget _cell(String text, {bool header = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.all(4),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: header ? 10 : 9,
        fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
      ),
    ),
  );
}

String _expenseField(Map<String, dynamic> e, String a, [String? b, String? c]) {
  for (final k in [a, b, c]) {
    if (k == null) continue;
    final v = e[k];
    if (v != null && v.toString().isNotEmpty) {
      return v.toString();
    }
  }
  return '-';
}

