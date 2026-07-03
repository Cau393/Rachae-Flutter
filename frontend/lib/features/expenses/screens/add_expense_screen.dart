import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/core/currency/default_currency.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;

import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/dashboard/providers/activity_feed_provider.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/providers/add_expense_notifier.dart';
import 'package:frontend/features/expenses/providers/group_expense_list_provider.dart';
import 'package:frontend/features/expenses/widgets/amount_field.dart';
import 'package:frontend/features/expenses/widgets/category_chips.dart';
import 'package:frontend/features/expenses/widgets/paid_by_dropdown.dart';
import 'package:frontend/features/expenses/widgets/receipt_upload_row.dart';
import 'package:frontend/features/expenses/widgets/split_details_panel.dart';
import 'package:frontend/features/expenses/widgets/split_method_selector.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';
import 'package:frontend/features/groups/providers/group_balances_provider.dart';
import 'package:frontend/features/groups/providers/group_detail_provider.dart';
import 'package:frontend/features/groups/providers/group_list_provider.dart';
import 'package:frontend/features/groups/widgets/currency_dropdown.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  String _fallbackLocation(String? groupId) {
    if (groupId != null && groupId.isNotEmpty) {
      return '/groups/$groupId';
    }
    return '/dashboard';
  }

  void _exitScreen(String? groupId) {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(_fallbackLocation(groupId));
  }

  AppBar _buildAppBar(AppLocalizations l10n, String? groupId) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: l10n.closeLabel,
        onPressed: () => _exitScreen(groupId),
      ),
      title: Text(l10n.addExpenseTitle),
    );
  }

  GroupMemberModel _syntheticMember(supa.User user, String backendUserId) {
    final meta = user.userMetadata;
    final name =
        meta?['full_name'] as String? ??
        meta?['name'] as String? ??
        user.email ??
        user.id;
    return GroupMemberModel(
      userId: backendUserId,
      displayName: name,
      avatarUrl: null,
      role: 'MEMBER',
      joinedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      invitedBy: null,
    );
  }

  GroupMemberModel _friendMember(FriendModel friend) {
    return GroupMemberModel(
      userId: friend.id,
      displayName: friend.displayName,
      avatarUrl: friend.avatarUrl,
      role: 'MEMBER',
      joinedAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      invitedBy: null,
    );
  }

  Future<void> _onDateTap(AddExpenseParams params) async {
    final current = ref.read(addExpenseNotifierProvider(params));
    final picked = await showDatePicker(
      context: context,
      initialDate: current.expenseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (!mounted) return;
    if (picked != null) {
      ref
          .read(addExpenseNotifierProvider(params).notifier)
          .updateExpenseDate(picked);
    }
  }

  Future<void> _onAddReceipt(AddExpenseParams params) async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (!mounted) return;
    if (file == null) return;
    ref
        .read(addExpenseNotifierProvider(params).notifier)
        .addReceiptFile(File(file.path));
  }

  Future<void> _handleSubmit(
    AppLocalizations l10n,
    AddExpenseParams params,
    String? groupId,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(addExpenseNotifierProvider(params).notifier);
    ExpenseDetailModel? detail;
    try {
      detail = await notifier.submit();
    } on DioException catch (e) {
      if (!mounted) return;
      final isTimeout =
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout;
      // Surface the backend's actual validation message (e.g. which split
      // failed) instead of a generic string — the interceptor already wraps
      // 4xx/5xx errors as ApiException in api_client.dart.
      final apiError = e.error;
      final errorMessage = isTimeout
          ? l10n.addExpenseTimeoutError
          : apiError is ApiException
          ? apiError.message
          : l10n.addExpenseError;
      messenger.showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(l10n.addExpenseError)));
      return;
    }

    if (!mounted) return;
    if (detail == null) return;

    final failedReceiptCount = ref
        .read(addExpenseNotifierProvider(params))
        .failedReceiptCount;

    final gid = groupId;
    if (gid != null && gid.isNotEmpty) {
      ref.invalidate(groupExpenseListProvider(gid));
      ref.invalidate(groupBalancesProvider(gid));
    }
    ref.invalidate(balanceSummaryProvider);
    ref.invalidate(activityFeedProvider);
    ref.invalidate(groupListProvider);

    if (!mounted) return;
    _exitScreen(groupId);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failedReceiptCount > 0
              ? l10n.addExpenseReceiptUploadPartialFailure
              : l10n.addExpenseSuccess,
        ),
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations l10n,
    AddExpenseParams params,
    String? groupId,
  ) {
    final state = ref.watch(addExpenseNotifierProvider(params));
    final notifier = ref.read(addExpenseNotifierProvider(params).notifier);
    final dateFormat = DateFormat.yMMMd(
      Localizations.localeOf(context).toString(),
    );
    final isPersonalExpense = (groupId ?? '').isEmpty;
    final personalFriendOptions = state.availablePeople
        .where((person) => person.userId != params.backendUserId)
        .toList();
    final showFriendError =
        state.validationError == addExpenseFriendRequired && isPersonalExpense;

    return Scaffold(
      appBar: _buildAppBar(l10n, groupId),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AmountField(
              value: state.amount,
              currency: state.currency,
              onChanged: notifier.updateAmount,
              convertedPreview: state.convertedPreview,
              convertedPreviewCurrency: params.groupCurrency,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CurrencyDropdown(
                    currencyLabel: l10n.addExpenseCurrencyLabel,
                    value: state.currency,
                    onChanged: notifier.updateCurrency,
                  ),
                ),
                const SizedBox(width: 12),
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.currency,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: ValueKey<String>(
                'desc_${params.groupId}_${params.currentUserId}',
              ),
              initialValue: state.description,
              decoration: InputDecoration(
                labelText: l10n.addExpenseDescriptionLabel,
                hintText: l10n.addExpenseDescriptionHint,
              ),
              onChanged: notifier.updateDescription,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.addExpenseCategoryLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            CategoryChips(
              selectedCategory: state.category,
              onChanged: notifier.updateCategory,
            ),
            const SizedBox(height: 16),
            if (isPersonalExpense) ...[
              DropdownButtonFormField<String>(
                initialValue: state.selectedFriendUserId,
                decoration: InputDecoration(
                  labelText: l10n.addExpenseFriendLabel,
                  helperText: personalFriendOptions.isEmpty
                      ? l10n.addExpenseNoFriendsAvailable
                      : l10n.addExpenseFriendHint,
                  errorText: showFriendError
                      ? l10n.addExpenseFriendRequired
                      : null,
                ),
                items: personalFriendOptions
                    .map(
                      (person) => DropdownMenuItem<String>(
                        value: person.userId,
                        child: Text(
                          person.displayName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: personalFriendOptions.isEmpty
                    ? null
                    : notifier.updateSelectedFriend,
              ),
              const SizedBox(height: 16),
            ],
            PaidByDropdown(
              participants: state.participants,
              valueUserId: state.paidByUserId,
              onChanged: notifier.updatePaidBy,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.addExpenseDateLabel),
              subtitle: Text(dateFormat.format(state.expenseDate)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: () => _onDateTap(params),
            ),
            const SizedBox(height: 16),
            SplitMethodSelector(
              selectedMethod: state.splitMethod,
              onChanged: notifier.updateSplitMethod,
            ),
            const SizedBox(height: 16),
            SplitDetailsPanel(
              state: state,
              onAmountChanged: notifier.updateParticipantAmount,
              onShareChanged: notifier.updateParticipantShare,
            ),
            const SizedBox(height: 16),
            ReceiptUploadRow(
              receiptQueue: state.receiptQueue,
              onAddReceipt: () => _onAddReceipt(params),
              onRemoveReceipt: notifier.removeReceiptFile,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: state.isSubmitting
                  ? null
                  : () => _handleSubmit(l10n, params, groupId),
              child: state.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.addExpenseSaveButton),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final groupId = GoRouterState.of(context).uri.queryParameters['group_id'];
    final authAsync = ref.watch(authNotifierProvider);

    return authAsync.when(
      loading: () => Scaffold(
        appBar: _buildAppBar(l10n, groupId),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Scaffold(
        appBar: _buildAppBar(l10n, groupId),
        body: Center(child: Text(l10n.errorGeneric)),
      ),
      data: (auth) {
        if (!auth.isAuthenticated) {
          return Scaffold(
            appBar: _buildAppBar(l10n, groupId),
            body: Center(child: Text(l10n.errorGeneric)),
          );
        }
        final user = (auth as AuthStateAuthenticated).user;
        final uid = user.id;

        final balanceAsync = ref.watch(balanceSummaryProvider);
        return balanceAsync.when(
          loading: () => Scaffold(
            appBar: _buildAppBar(l10n, groupId),
            body: const Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Scaffold(
            appBar: _buildAppBar(l10n, groupId),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(l10n.errorGeneric),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => ref.invalidate(balanceSummaryProvider),
                    child: Text(l10n.retryLabel),
                  ),
                ],
              ),
            ),
          ),
          data: (balance) {
            final backendId = balance.userId;

            if (groupId != null && groupId.isNotEmpty) {
              final detailAsync = ref.watch(groupDetailProvider(groupId));
              return detailAsync.when(
                loading: () => Scaffold(
                  appBar: _buildAppBar(l10n, groupId),
                  body: const Center(child: CircularProgressIndicator()),
                ),
                error: (_, _) => Scaffold(
                  appBar: _buildAppBar(l10n, groupId),
                  body: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(l10n.errorGeneric),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () =>
                              ref.invalidate(groupDetailProvider(groupId)),
                          child: Text(l10n.retryLabel),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (detail) {
                  final params = AddExpenseParams(
                    groupId: groupId,
                    currentUserId: uid,
                    backendUserId: backendId,
                    members: detail.members,
                    groupCurrency: detail.currency,
                  );
                  return _buildForm(context, l10n, params, groupId);
                },
              );
            }

            final friendsAsync = ref.watch(friendsProvider);
            return friendsAsync.when(
              loading: () => Scaffold(
                appBar: _buildAppBar(l10n, groupId),
                body: const Center(child: CircularProgressIndicator()),
              ),
              error: (_, _) => Scaffold(
                appBar: _buildAppBar(l10n, groupId),
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(l10n.errorGeneric),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(friendsProvider),
                        child: Text(l10n.retryLabel),
                      ),
                    ],
                  ),
                ),
              ),
              data: (friends) {
                final params = AddExpenseParams(
                  groupId: null,
                  currentUserId: uid,
                  backendUserId: backendId,
                  members: [
                    _syntheticMember(user, backendId),
                    ...friends.map(_friendMember),
                  ],
                  groupCurrency: kDefaultCurrencyCode,
                );
                return _buildForm(context, l10n, params, null);
              },
            );
          },
        );
      },
    );
  }
}
