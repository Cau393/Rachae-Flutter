import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/profile/models/export_pdf_labels.dart';
import 'package:frontend/features/profile/providers/export_notifier.dart';
import 'package:frontend/features/profile/providers/export_share_pdf_provider.dart';
import 'package:frontend/features/profile/widgets/export_date_range_picker.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  DateTime? _from;
  DateTime? _to;
  String? _groupId;

  ExportPdfLabels _buildPdfLabels(AppLocalizations l10n) {
    final locale = Localizations.localeOf(context).toString();
    final df = DateFormat.yMMMd(locale);
    final fromStr = _from != null ? df.format(_from!) : '—';
    final toStr = _to != null ? df.format(_to!) : '—';
    return ExportPdfLabels(
      documentTitle: l10n.exportPdfDocumentTitle,
      emptyReportBody: l10n.exportPdfEmptyReport,
      periodLine: l10n.exportPdfPeriod(fromStr, toStr),
      totalSpentLabel: l10n.exportPdfTotalSpent,
      perPersonTitle: l10n.exportPdfPerPersonTitle,
      columnPerson: l10n.exportPdfColumnPerson,
      columnPaid: l10n.exportPdfColumnPaid,
      columnOwed: l10n.exportPdfColumnOwed,
      columnNet: l10n.exportPdfColumnNet,
      expensesTitle: l10n.exportPdfExpensesTitle,
      noExpenses: l10n.exportPdfNoExpenses,
      expenseDescription: l10n.exportPdfExpenseDescription,
      expenseAmount: l10n.exportPdfExpenseAmount,
      expenseDate: l10n.exportPdfExpenseDate,
      expenseCategory: l10n.exportPdfExpenseCategory,
      settlementsTitle: l10n.exportPdfSettlementsTitle,
      noSettlements: l10n.exportPdfNoSettlements,
      settlementPayer: l10n.exportPdfSettlementPayer,
      settlementReceiver: l10n.exportPdfSettlementReceiver,
      settlementAmount: l10n.exportPdfSettlementAmount,
      settlementDate: l10n.exportPdfSettlementDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupsAsync = ref.watch(groupListProvider);
    final exportAsync = ref.watch(exportNotifierProvider);
    final isGenerating = switch (exportAsync) {
      AsyncData(:final value) => value?.isGenerating ?? false,
      _ => false,
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExportDateRangePicker(
              onChanged: (from, to) {
                setState(() {
                  _from = from;
                  _to = to;
                });
              },
            ),
            const SizedBox(height: 16),
            groupsAsync.when(
              data: (List<GroupSummaryModel> groups) {
                return DropdownButtonFormField<String?>(
                  decoration: InputDecoration(labelText: l10n.exportGroupLabel),
                  // ignore: deprecated_member_use — selection driven by [_groupId]; value tracks user choice.
                  value: _groupId,
                  items: [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text(l10n.exportAllGroups),
                    ),
                    ...groups.map(
                      (g) => DropdownMenuItem<String?>(
                        value: g.id,
                        child: Text(g.name),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _groupId = v),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text(l10n.sectionLoadError),
            ),
            const Spacer(),
            FilledButton(
              onPressed: (_from == null || _to == null || isGenerating)
                  ? null
                  : () async {
                      final pdfLabels = _buildPdfLabels(l10n);
                      await ref
                          .read(exportNotifierProvider.notifier)
                          .generateReport(
                            groupId: _groupId,
                            from: _from,
                            to: _to,
                            pdfLabels: pdfLabels,
                          );
                      if (!context.mounted) return;
                      final av = ref.read(exportNotifierProvider);
                      final state = switch (av) {
                        AsyncData(:final value) => value,
                        _ => null,
                      };
                      final messenger = ScaffoldMessenger.of(context);
                      final bytes = state?.pdfBytes;
                      if (bytes != null) {
                        await ref.read(exportSharePdfProvider)(bytes);
                        if (context.mounted) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(l10n.exportSuccess)),
                          );
                        }
                      } else if (state?.error != null) {
                        messenger.showSnackBar(
                          SnackBar(content: Text(l10n.exportError)),
                        );
                      }
                    },
              child: isGenerating
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.exportGenerateButton),
            ),
          ],
        ),
      ),
    );
  }
}
