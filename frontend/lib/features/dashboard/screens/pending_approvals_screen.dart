import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/friends/widgets/pending_transaction_tile.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final txnsAsync = ref.watch(pendingIncomingSettlementsProvider);
    final balanceAsync = ref.watch(balanceSummaryProvider);

    final djangoUserId = balanceAsync.maybeWhen(
      data: (m) => m.userId,
      orElse: () => '',
    );

    Future<void> onConfirm(String id) async {
      await ref.read(settlementRepositoryProvider).confirmTransaction(id);
      ref.invalidate(pendingIncomingSettlementsProvider);
      ref.invalidate(balanceSummaryProvider);
    }

    Future<void> onDispute(String id) async {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          content: Text(l10n.settleUpDisputeConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(l10n.cancelLabel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(l10n.confirmLabel),
            ),
          ],
        ),
      );
      if (confirmed != true || !context.mounted) return;
      await ref.read(settlementRepositoryProvider).disputeTransaction(id);
      ref.invalidate(pendingIncomingSettlementsProvider);
      ref.invalidate(balanceSummaryProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardPendingApprovalsTitle),
      ),
      body: txnsAsync.when(
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.dashboardPendingApprovalsEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: list.length,
            itemBuilder: (context, i) {
              final t = list[i];
              return PendingTransactionTile(
                transaction: t,
                currentUserId: djangoUserId,
                onConfirm: () => onConfirm(t.id),
                onDispute: () => onDispute(t.id),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Center(child: Text(l10n.errorGeneric)),
      ),
    );
  }
}
