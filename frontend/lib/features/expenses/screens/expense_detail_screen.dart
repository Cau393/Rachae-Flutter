import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/providers/expense_detail_provider.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';
import 'package:frontend/features/expenses/providers/group_expense_list_provider.dart';
import 'package:frontend/features/expenses/widgets/expense_header.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/expenses/widgets/receipt_gallery.dart';
import 'package:frontend/features/expenses/widgets/split_breakdown_list.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

String _fallbackExpenseLocation(String? groupId) {
  if (groupId != null && groupId.isNotEmpty) {
    return '/groups/$groupId';
  }
  return '/dashboard';
}

void _exitExpenseScreen(BuildContext context, String? groupId) {
  if (context.canPop()) {
    context.pop();
    return;
  }
  context.go(_fallbackExpenseLocation(groupId));
}

AppBar _buildExpenseDetailAppBar(
  BuildContext context,
  AppLocalizations l10n, {
  required String? groupId,
  List<Widget> actions = const [],
}) {
  return AppBar(
    leading: IconButton(
      icon: const Icon(Icons.close),
      tooltip: l10n.closeLabel,
      onPressed: () => _exitExpenseScreen(context, groupId),
    ),
    title: Text(l10n.expenseDetailTitle),
    actions: actions,
  );
}

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final auth = ref.watch(authNotifierProvider);
    final detailAsync = ref.watch(expenseDetailProvider(expenseId));

    final currentUserId = switch (auth.value) {
      AuthStateAuthenticated(:final user) => user.id,
      _ => '',
    };

    return detailAsync.when(
      loading: () => Scaffold(
        appBar: _buildExpenseDetailAppBar(
          context,
          l10n,
          groupId: null,
        ),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: _buildExpenseDetailAppBar(
          context,
          l10n,
          groupId: null,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.errorGeneric),
              TextButton(
                onPressed: () =>
                    ref.invalidate(expenseDetailProvider(expenseId)),
                child: Text(l10n.retryLabel),
              ),
            ],
          ),
        ),
      ),
      data: (detail) {
        final isAuthorized = detail.isAuthorizedToEdit(currentUserId);
        return Scaffold(
          appBar: _buildExpenseDetailAppBar(
            context,
            l10n,
            groupId: detail.groupId,
            actions: [
              if (isAuthorized) ...[
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: l10n.expenseDetailEditButton,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.expenseDetailEditComingSoon)),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: l10n.expenseDetailDeleteButton,
                  onPressed: () => _showDeleteDialog(
                    context,
                    ref,
                    l10n,
                    expenseId,
                    detail,
                  ),
                ),
              ],
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ExpenseHeader(model: detail),
                const SizedBox(height: 16),
                SplitBreakdownList(detail: detail),
                const SizedBox(height: 16),
                ReceiptGallery(receiptUrls: detail.receiptUrls),
                const SizedBox(height: 16),
                Text(
                  l10n.expenseDetailLastModified(
                    DateFormat('dd/MM/yyyy HH:mm')
                        .format(detail.updatedAt.toLocal()),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Future<void> _showDeleteDialog(
  BuildContext context,
  WidgetRef ref,
  AppLocalizations l10n,
  String expenseId,
  ExpenseDetailModel detail,
) async {
  final messenger = ScaffoldMessenger.of(context);
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        content: Text(l10n.expenseDetailDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancelLabel),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                await ref
                    .read(expenseRepositoryProvider)
                    .deleteExpense(expenseId);
                if (!context.mounted) return;
                final gid = detail.groupId;
                if (gid != null && gid.isNotEmpty) {
                  ref.invalidate(groupExpenseListProvider(gid));
                }
                ref.invalidate(balanceSummaryProvider);
                ref.invalidate(activityFeedProvider);
                ref.invalidate(groupListProvider);
                _exitExpenseScreen(context, gid);
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.expenseDetailDeleteSuccess)),
                );
              } catch (_) {
                if (!context.mounted) return;
                messenger.showSnackBar(
                  SnackBar(content: Text(l10n.errorGeneric)),
                );
              }
            },
            child: Text(l10n.expenseDetailDeleteButton),
          ),
        ],
      );
    },
  );
}
