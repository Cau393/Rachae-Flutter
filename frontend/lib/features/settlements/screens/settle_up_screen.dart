import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:frontend/core/currency/currency_formatter.dart';
import 'package:frontend/core/currency/default_currency.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/expenses/widgets/amount_field.dart';
import 'package:frontend/features/expenses/widgets/receipt_upload_row.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/settlements/providers/settle_up_notifier.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

extension SettleUpScreenL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}

/// Full settle-up UI (Phase 21). Query: `receiver_id`, `amount`, `currency`, `group_id`.
class SettleUpScreen extends ConsumerStatefulWidget {
  const SettleUpScreen({super.key});

  @override
  ConsumerState<SettleUpScreen> createState() => _SettleUpScreenState();
}

class _SettleUpScreenState extends ConsumerState<SettleUpScreen> {
  bool _routeParamsRead = false;
  String _receiverId = '';
  String _amount = '';
  String _currency = kDefaultCurrencyCode;
  String _groupId = '';
  String _note = '';
  bool _isLoading = false;
  bool _amountPrefilledFromQuery = false;
  final List<File> _proofQueue = <File>[];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readRouteQueryParamsOnce();
    });
  }

  void _readRouteQueryParamsOnce() {
    if (!mounted || _routeParamsRead) {
      return;
    }
    _routeParamsRead = true;
    final q = GoRouterState.of(context).uri.queryParameters;
    final rawAmount = q['amount'];
    final hadAmountParam =
        rawAmount != null && rawAmount.trim().isNotEmpty;
    setState(() {
      _receiverId = q['receiver_id'] ?? '';
      _amount = hadAmountParam
          ? CurrencyFormatter.normalizeDecimalInput(rawAmount)
          : '';
      _amountPrefilledFromQuery = hadAmountParam;
      _currency = q['currency'] ?? kDefaultCurrencyCode;
      _groupId = q['group_id'] ?? '';
    });
  }

  String _displayNameForUser(User user) {
    final meta = user.userMetadata;
    final name = meta?['full_name'] as String? ?? meta?['name'] as String?;
    return name ?? user.email ?? user.id;
  }

  void _exitScreen() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go('/dashboard');
  }

  Future<void> _onAddProof() async {
    final file = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (!mounted || file == null) return;
    setState(() => _proofQueue.add(File(file.path)));
  }

  Future<void> _uploadProof(String transactionId, File file) async {
    final contentType = _contentTypeForFile(file);
    final url = await ref.read(settlementRepositoryProvider).fetchProofUploadUrl(
          transactionId,
          contentType: contentType,
        );
    final bytes = await file.readAsBytes();
    final response = await http.put(
      Uri.parse(url.uploadUrl),
      body: bytes,
      headers: <String, String>{'Content-Type': contentType},
    );
    if (response.statusCode >= 400) {
      throw Exception('S3 upload failed: ${response.statusCode}');
    }
    await ref.read(settlementRepositoryProvider).confirmProofUpload(
          transactionId,
          url.fileKey,
        );
  }

  static String _contentTypeForFile(File f) {
    final p = f.path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }

  Future<void> _handleRecord() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    setState(() => _isLoading = true);
    try {
      final txn = await ref.read(settleUpNotifierProvider.notifier).recordPayment(
            receiverId: _receiverId,
            amount: _amount,
            currency: _currency,
            groupId: _groupId.isEmpty ? null : _groupId,
            note: _note.trim().isEmpty ? null : _note.trim(),
          );
      if (txn != null && _proofQueue.isNotEmpty) {
        var proofFailed = false;
        for (final file in List<File>.from(_proofQueue)) {
          try {
            await _uploadProof(txn.id, file);
          } catch (_) {
            proofFailed = true;
          }
        }
        if (proofFailed && mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.settleUpProofUploadError)),
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _proofQueue.clear();
      });
      messenger.showSnackBar(SnackBar(content: Text(l10n.settleUpSuccess)));
      _exitScreen();
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
        messenger.showSnackBar(SnackBar(content: Text(l10n.settleUpError)));
      }
    }
  }

  Widget _payerRow(AppLocalizations l10n, User user) {
    final theme = Theme.of(context);
    final meta = user.userMetadata;
    final avatarUrl = meta?['avatar_url'] as String?;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          l10n.settleUpPayerLabel,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(width: 12),
        CircleAvatar(
          radius: 20,
          backgroundImage:
              avatarUrl != null && avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
          child: avatarUrl == null || avatarUrl.isEmpty
              ? Icon(Icons.person, size: 22, color: theme.colorScheme.onSurfaceVariant)
              : null,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            _displayNameForUser(user),
            style: theme.textTheme.titleMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _receiverSection(AppLocalizations l10n, List<FriendModel> friends) {
    final theme = Theme.of(context);

    if (_receiverId.isNotEmpty) {
      String label = _receiverId;
      for (final f in friends) {
        if (f.id == _receiverId) {
          label = f.displayName;
          break;
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.settleUpReceiverLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(label, style: theme.textTheme.titleMedium),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: l10n.settleUpReceiverLabel),
      items: friends
          .map(
            (f) => DropdownMenuItem<String>(
              value: f.id,
              child: Text(f.displayName),
            ),
          )
          .toList(),
      onChanged: (v) => setState(() => _receiverId = v ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    final friendsAsync = ref.watch(friendsProvider);
    final authAsync = ref.watch(authNotifierProvider);

    final suggestedFormatted = _amountPrefilledFromQuery && _amount.isNotEmpty
        ? l10n.settleUpSuggestedAmount(
            CurrencyFormatter.formatRawDecimalForDisplay(_amount, _currency),
          )
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settleUpTitle),
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: l10n.closeLabel,
          onPressed: _exitScreen,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            authAsync.maybeWhen(
              data: (state) {
                if (state case AuthStateAuthenticated(:final user)) {
                  return _payerRow(l10n, user);
                }
                return const SizedBox.shrink();
              },
              orElse: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            friendsAsync.when(
              data: (friends) => _receiverSection(l10n, friends),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => Text(
                l10n.settleUpError,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            const SizedBox(height: 16),
            AmountField(
              value: _amount,
              currency: _currency,
              onChanged: (v) => setState(() => _amount = v),
            ),
            if (suggestedFormatted != null) ...[
              const SizedBox(height: 8),
              Text(
                suggestedFormatted,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              decoration: InputDecoration(
                labelText: l10n.settleUpNoteLabel,
                hintText: l10n.settleUpNoteHint,
              ),
              onChanged: (v) => setState(() => _note = v),
            ),
            const SizedBox(height: 8),
            Text(_currency, style: theme.textTheme.bodySmall),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                l10n.settleUpPaymentProofSection,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: 8),
            ReceiptUploadRow(
              receiptQueue: _proofQueue,
              onAddReceipt: _onAddProof,
              onRemoveReceipt: (f) => setState(() => _proofQueue.remove(f)),
              addButtonLabel: l10n.settleUpAddProofLabel,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: (_receiverId.isEmpty ||
                      _amount.isEmpty ||
                      _isLoading)
                  ? null
                  : _handleRecord,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.settleUpRecordButton),
            ),
          ],
        ),
      ),
    );
  }
}
