import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/features/dashboard/dashboard_refresh.dart';
import 'package:frontend/features/dashboard/models/pairwise_balance_row_model.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/providers/dashboard_shortcuts_providers.dart';
import 'package:frontend/features/friends/widgets/pending_transaction_tile.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class PendingSettlementsScreen extends ConsumerWidget {
  const PendingSettlementsScreen({super.key});

  static String _absBalanceRaw(String raw) {
    final t = raw.trim();
    if (t.startsWith('-')) {
      return t.substring(1);
    }
    return t;
  }

  static bool _isNegativeBalance(PairwiseBalanceRowModel row) {
    return row.balanceAsMoneyAmount.isNegative;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final outAsync = ref.watch(pendingOutgoingSettlementsProvider);
    final pairAsync = ref.watch(pairwiseBalancesProvider);
    final balanceAsync = ref.watch(balanceSummaryProvider);

    final djangoUserId = balanceAsync.maybeWhen(
      data: (m) => m.userId,
      orElse: () => '',
    );

    Future<void> onConfirm(String id) async {
      try {
        await ref.read(settlementRepositoryProvider).confirmTransaction(id);
        await refreshDashboardData(ref);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneric)),
          );
        }
      }
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
      try {
        await ref.read(settlementRepositoryProvider).disputeTransaction(id);
        await refreshDashboardData(ref);
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.errorGeneric)),
          );
        }
      }
    }

    if (outAsync.isLoading || pairAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dashboardPendingSettlementsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (outAsync.hasError || pairAsync.hasError) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.dashboardPendingSettlementsTitle)),
        body: Center(child: Text(l10n.errorGeneric)),
      );
    }

    final allOutgoing = outAsync.value ?? [];
    final outgoing = djangoUserId.isEmpty
        ? allOutgoing
        : allOutgoing.where((t) => t.payer.userId == djangoUserId).toList();
    final pairwise = pairAsync.value ?? [];
    final youOwe = pairwise.where(_isNegativeBalance).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardPendingSettlementsTitle),
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshDashboardData(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (outgoing.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  l10n.dashboardPendingOutgoingSection,
                  style: theme.textTheme.titleSmall,
                ),
              ),
              ...outgoing.map(
                (t) => PendingTransactionTile(
                  transaction: t,
                  currentUserId: djangoUserId,
                  onConfirm: () => onConfirm(t.id),
                  onDispute: () => onDispute(t.id),
                ),
              ),
            ],
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                l10n.dashboardYouOweSection,
                style: theme.textTheme.titleSmall,
              ),
            ),
            if (youOwe.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.dashboardYouOweEmpty,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              )
            else
              ...youOwe.map((r) => _oweTile(context, l10n, r)),
          ],
        ),
      ),
    );
  }

  Widget _oweTile(
    BuildContext context,
    AppLocalizations l10n,
    PairwiseBalanceRowModel row,
  ) {
    final abs = _absBalanceRaw(row.balance);
    return ListTile(
      leading: const Icon(Icons.payments_outlined),
      title: Text(row.displayName),
      subtitle: Text(l10n.dashboardYouOweSubtitle),
      trailing: CurrencyFormatterWidget(amount: row.balanceAsMoneyAmount),
      onTap: () {
        final uri = Uri(
          path: '/settle',
          queryParameters: <String, String>{
            'receiver_id': row.userId,
            'amount': abs,
            'currency': row.currency,
          },
        );
        context.push(uri.toString());
      },
    );
  }
}
