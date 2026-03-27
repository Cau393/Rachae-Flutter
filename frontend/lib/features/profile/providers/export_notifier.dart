import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/features/groups/models/group_report_model.dart';
import 'package:frontend/features/groups/providers/group_repository_provider.dart';
import 'package:frontend/features/profile/models/export_pdf_labels.dart';
import 'package:frontend/features/profile/services/export_pdf_builder.dart';

final exportNotifierProvider =
    AsyncNotifierProvider.autoDispose<ExportNotifier, ExportState?>(
  ExportNotifier.new,
);

@immutable
class ExportState {
  const ExportState({
    required this.isGenerating,
    this.pdfBytes,
    this.error,
  });

  final bool isGenerating;
  final Uint8List? pdfBytes;
  final String? error;
}

class ExportNotifier extends AsyncNotifier<ExportState?> {
  @override
  Future<ExportState?> build() async => null;

  Future<void> generateReport({
    String? groupId,
    DateTime? from,
    DateTime? to,
    required ExportPdfLabels pdfLabels,
  }) async {
    state = const AsyncData(ExportState(isGenerating: true));
    try {
      final repo = ref.read(groupRepositoryProvider);
      final List<GroupReportModel> reportData;
      if (groupId != null) {
        reportData = [
          await repo.fetchGroupReport(groupId, from: from, to: to),
        ];
      } else {
        final groups = await repo.fetchGroups();
        reportData = <GroupReportModel>[];
        for (final g in groups) {
          reportData.add(
            await repo.fetchGroupReport(g.id, from: from, to: to),
          );
        }
      }
      final pdfBytes = await buildExportPdf(reportData, pdfLabels);
      state = AsyncData(
        ExportState(isGenerating: false, pdfBytes: pdfBytes),
      );
    } catch (e) {
      state = AsyncData(
        ExportState(isGenerating: false, error: e.toString()),
      );
    }
  }
}
