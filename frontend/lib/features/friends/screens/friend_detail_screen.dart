import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/currency/currency_formatter.dart';
import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/dashboard/widgets/expense_list_tile.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/friends/models/friend_balance_model.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friend_balance_provider.dart';
import 'package:frontend/features/friends/providers/friend_shared_expenses_provider.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/friends/widgets/add_friend_to_group_sheet.dart';
import 'package:frontend/features/friends/widgets/pending_transaction_tile.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/pending_transactions_provider.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

const _kAvatarDiameter = 56.0;

class FriendDetailScreen extends ConsumerWidget {
  const FriendDetailScreen({super.key, required this.friendId});

  final String friendId;

  String? _currentUserId(WidgetRef ref) {
    final auth = ref.watch(authNotifierProvider).value;
    return switch (auth) {
      AuthStateAuthenticated(:final user) => user.id,
      _ => null,
    };
  }

  FriendModel? _friendFromList(AsyncValue<List<FriendModel>> friendsAsync) {
    if (!friendsAsync.hasValue) return null;
    try {
      return friendsAsync.value!.firstWhere((f) => f.id == friendId);
    } catch (_) {
      return null;
    }
  }

  static String _absoluteFormattedAmount(FriendBalanceModel balance) {
    final raw = balance.balance.trim();
    final absRaw = raw.startsWith('-') ? raw.substring(1) : raw;
    return CurrencyFormatter.format(
      MoneyAmount.fromApiString(absRaw, balance.currency),
    );
  }

  Future<void> _refreshProviders(WidgetRef ref) async {
    ref.invalidate(friendBalanceProvider(friendId));
    ref.invalidate(pendingTransactionsProvider(friendId));
    ref.invalidate(friendSharedExpensesProvider(friendId));
    await Future.wait([
      ref.read(friendBalanceProvider(friendId).future),
      ref.read(pendingTransactionsProvider(friendId).future),
      ref.read(friendSharedExpensesProvider(friendId).future),
    ]);
  }

  Future<void> _onConfirmPayment(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
  ) async {
    await ref
        .read(settlementRepositoryProvider)
        .confirmTransaction(transactionId);
    if (!context.mounted) return;
    ref.invalidate(pendingTransactionsProvider(friendId));
    ref.invalidate(friendBalanceProvider(friendId));
  }

  Future<void> _onDisputePayment(
    BuildContext context,
    WidgetRef ref,
    String transactionId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
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
    await ref
        .read(settlementRepositoryProvider)
        .disputeTransaction(transactionId);
    if (!context.mounted) return;
    ref.invalidate(pendingTransactionsProvider(friendId));
    ref.invalidate(friendBalanceProvider(friendId));
  }

  void _goSettle(BuildContext context, FriendBalanceModel balance) {
    final absAmount = balance.balance.trim().startsWith('-')
        ? balance.balance.trim().substring(1)
        : balance.balance.trim();
    final uri = Uri(
      path: '/settle',
      queryParameters: <String, String>{
        'receiver_id': friendId,
        'amount': absAmount,
        'currency': balance.currency,
      },
    );
    context.go(uri.toString());
  }

  void _exitScreen(BuildContext context) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/friends');
  }

  void _showAddToGroupSheet(BuildContext context, FriendModel friend) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddFriendToGroupSheet(
        friendId: friend.id,
        friendName: friend.displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final friendsAsync = ref.watch(friendsProvider);
    final balanceAsync = ref.watch(friendBalanceProvider(friendId));
    final pendingAsync = ref.watch(pendingTransactionsProvider(friendId));
    final expensesAsync = ref.watch(friendSharedExpensesProvider(friendId));

    final loading =
        friendsAsync.isLoading ||
        balanceAsync.isLoading ||
        pendingAsync.isLoading ||
        expensesAsync.isLoading;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => _exitScreen(context),
        ),
        title: Text(l10n.friendDetailTitle),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => _refreshProviders(ref),
              child: _buildLoadedBody(
                context,
                ref,
                theme,
                l10n,
                friendsAsync,
                balanceAsync,
                pendingAsync,
                expensesAsync,
              ),
            ),
    );
  }

  Widget _buildLoadedBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    AppLocalizations l10n,
    AsyncValue<List<FriendModel>> friendsAsync,
    AsyncValue<FriendBalanceModel> balanceAsync,
    AsyncValue<List<TransactionModel>> pendingAsync,
    AsyncValue<List<ExpenseListModel>> expensesAsync,
  ) {
    final friend = _friendFromList(friendsAsync);
    if (friend == null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.3,
            child: Center(child: Text(l10n.errorGeneric)),
          ),
        ],
      );
    }

    final FriendBalanceModel? balance = switch (balanceAsync) {
      AsyncData(:final value) => value,
      _ => null,
    };
    final List<TransactionModel> pending = switch (pendingAsync) {
      AsyncData(:final value) => value,
      _ => const <TransactionModel>[],
    };
    final List<ExpenseListModel> expenses = switch (expensesAsync) {
      AsyncData(:final value) => value,
      _ => const <ExpenseListModel>[],
    };
    final currentUid = _currentUserId(ref) ?? '';

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FriendHeader(friend: friend),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showAddToGroupSheet(context, friend),
              icon: const Icon(Icons.group_add_outlined),
              label: Text(l10n.friendDetailAddToGroupButton),
            ),
          ),
          const SizedBox(height: 16),
          if (balance != null) ...[
            _BalanceCard(
              balance: balance,
              l10n: l10n,
              theme: theme,
              onSettle: balance.isNegative
                  ? () => _goSettle(context, balance)
                  : null,
            ),
            const SizedBox(height: 16),
          ],
          if (pending.isNotEmpty) ...[
            Text(
              l10n.friendDetailPendingSettlements,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pending.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final t = pending[i];
                return PendingTransactionTile(
                  transaction: t,
                  currentUserId: currentUid,
                  onConfirm: () => _onConfirmPayment(context, ref, t.id),
                  onDispute: () => _onDisputePayment(context, ref, t.id),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
          Text(
            l10n.friendDetailSharedExpenses,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          if (expenses.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.friendDetailNoSharedExpenses,
                textAlign: TextAlign.center,
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: expenses.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final e = expenses[i];
                final activity = ExpenseActivity.fromExpenseListModel(e);
                return ExpenseListTile(
                  item: activity,
                  onTap: () => context.go('/expenses/${e.id}'),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _FriendHeader extends StatelessWidget {
  const _FriendHeader({required this.friend});

  final FriendModel friend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final url = friend.avatarUrl?.trim();
    final hasAvatar = url != null && url.isNotEmpty;

    final initialsStyle = const TextStyle(fontWeight: FontWeight.bold);

    final Widget avatarChild = hasAvatar
        ? ClipOval(
            child: CachedNetworkImage(
              imageUrl: url,
              width: _kAvatarDiameter,
              height: _kAvatarDiameter,
              fit: BoxFit.cover,
              placeholder: (context, _) =>
                  Center(child: Text(friend.initials, style: initialsStyle)),
              errorWidget: (context, url, err) =>
                  Center(child: Text(friend.initials, style: initialsStyle)),
            ),
          )
        : Text(friend.initials, style: initialsStyle);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: _kAvatarDiameter / 2,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: avatarChild,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(friend.displayName, style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(friend.email, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.balance,
    required this.l10n,
    required this.theme,
    required this.onSettle,
  });

  final FriendBalanceModel balance;
  final AppLocalizations l10n;
  final ThemeData theme;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final formattedAbs = FriendDetailScreen._absoluteFormattedAmount(balance);
    final statusText = balance.isPositive
        ? l10n.friendsOwed(formattedAbs)
        : balance.isNegative
        ? l10n.friendsOwes(formattedAbs)
        : l10n.friendsEven;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CurrencyFormatterWidget(
              amount: balance.balanceAsMoneyAmount,
              colorCoded: true,
              showSign: true,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(statusText),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onSettle,
              child: Text(l10n.friendDetailSettleUpButton),
            ),
          ],
        ),
      ),
    );
  }
}
