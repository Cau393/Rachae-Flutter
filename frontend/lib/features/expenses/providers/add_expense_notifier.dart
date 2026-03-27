import 'dart:async' show unawaited;
import 'dart:io';

import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import 'package:frontend/core/currency/currency_formatter.dart';
import 'package:frontend/core/currency/default_currency.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/models/expense_form_state.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';

/// ARB key — resolve in widgets via `context.l10n`.
const String addExpenseSplitDoesNotMatch = 'addExpenseSplitDoesNotMatch';

/// ARB key — amount missing, unparsable, or not greater than zero.
const String addExpenseAmountInvalid = 'addExpenseAmountInvalid';

/// ARB key — personal expenses require selecting exactly one friend.
const String addExpenseFriendRequired = 'addExpenseFriendRequired';

@immutable
class AddExpenseParams {
  const AddExpenseParams({
    this.groupId,
    required this.currentUserId,
    required this.backendUserId,
    this.members = const [],
    this.groupCurrency = kDefaultCurrencyCode,
  });

  final String? groupId;

  /// Supabase auth user id (session). Used for keys / display only.
  final String currentUserId;

  /// Django `User.id` from API — required for `paid_by` and split `user_id`s.
  final String backendUserId;
  final List<GroupMemberModel> members;
  final String groupCurrency;

  @override
  bool operator ==(Object other) {
    if (other is! AddExpenseParams) return false;
    if (other.groupId != groupId ||
        other.currentUserId != currentUserId ||
        other.backendUserId != backendUserId ||
        other.groupCurrency != groupCurrency) {
      return false;
    }
    if (other.members.length != members.length) return false;
    for (var i = 0; i < members.length; i++) {
      if (other.members[i].userId != members[i].userId) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
    groupId,
    currentUserId,
    backendUserId,
    groupCurrency,
    Object.hashAll(members.map((m) => m.userId)),
  );
}

final addExpenseNotifierProvider = NotifierProvider.autoDispose
    .family<AddExpenseNotifier, AddExpenseFormState, AddExpenseParams>(
      AddExpenseNotifier.new,
    );

class AddExpenseNotifier extends Notifier<AddExpenseFormState> {
  AddExpenseNotifier(this.params);

  final AddExpenseParams params;

  static const _hashtagToSlug = <String, String>{
    '#geral': 'geral',
    '#comida': 'comida',
    '#transporte': 'transporte',
    '#moradia': 'moradia',
    '#lazer': 'lazer',
    '#viagem': 'viagem',
    '#utilidades': 'utilidades',
  };

  static final Decimal _splitTolerance = Decimal.parse('0.01');

  ExpenseRepository get _repo => ref.read(expenseRepositoryProvider);

  bool get _isGroupExpense => (params.groupId ?? '').isNotEmpty;

  List<SplitParticipant> get _availablePeople => params.members
      .map(
        (m) => SplitParticipant(userId: m.userId, displayName: m.displayName),
      )
      .toList();

  SplitParticipant? _personById(String userId) {
    for (final person in state.availablePeople) {
      if (person.userId == userId) {
        return person;
      }
    }
    return null;
  }

  @override
  AddExpenseFormState build() {
    final availablePeople = _availablePeople;
    final initialParticipants = _isGroupExpense
        ? availablePeople
        : availablePeople
              .where((person) => person.userId == params.backendUserId)
              .toList();

    return AddExpenseFormState(
      paidByUserId: params.backendUserId,
      currency: params.groupCurrency,
      availablePeople: availablePeople,
      participants: initialParticipants,
    );
  }

  void updateAmount(String value) {
    final clearAmountErr = state.validationError == addExpenseAmountInvalid;
    state = state.copyWith(
      amount: value,
      validationError: clearAmountErr ? null : state.validationError,
    );
    _fetchConversionPreview();
  }

  void updateDescription(String value) {
    state = state.copyWith(description: value);
    _parseCategoryFromHashtag(value);
  }

  void updateCategory(String slug) {
    state = state.copyWith(category: slug);
  }

  void updateCurrency(String code) {
    state = state.copyWith(currency: code);
    _fetchConversionPreview();
  }

  void updateExpenseDate(DateTime date) {
    state = state.copyWith(expenseDate: date);
  }

  void updateSplitMethod(String method) {
    state = state.copyWith(splitMethod: method, validationError: null);
  }

  void updatePaidBy(String userId) {
    state = state.copyWith(paidByUserId: userId);
  }

  void updateSelectedFriend(String? userId) {
    if (_isGroupExpense) {
      return;
    }

    final currentUser = _personById(params.backendUserId);
    if (currentUser == null) {
      return;
    }

    final selectedFriend = userId == null || userId.isEmpty
        ? null
        : _personById(userId);
    final nextParticipants = <SplitParticipant>[
      currentUser,
      if (selectedFriend != null && selectedFriend.userId != currentUser.userId)
        selectedFriend,
    ];
    final nextPaidBy =
        nextParticipants.any((p) => p.userId == state.paidByUserId)
        ? state.paidByUserId
        : params.backendUserId;
    final clearFriendErr = state.validationError == addExpenseFriendRequired;

    state = state.copyWith(
      selectedFriendUserId: selectedFriend?.userId,
      participants: nextParticipants,
      paidByUserId: nextPaidBy,
      validationError: clearFriendErr ? null : state.validationError,
    );
  }

  void updateParticipantAmount(String userId, String amount) {
    final normalized = CurrencyFormatter.normalizeDecimalInput(amount);
    final next = state.participants.map((p) {
      if (p.userId == userId) return p.copyWith(amountOwed: normalized);
      return p;
    }).toList();
    state = state.copyWith(participants: next);
  }

  void updateParticipantShare(String userId, String share) {
    final normalized = CurrencyFormatter.normalizeDecimalInput(share);
    final next = state.participants.map((p) {
      if (p.userId == userId) return p.copyWith(shareValue: normalized);
      return p;
    }).toList();
    state = state.copyWith(participants: next);
  }

  void addReceiptFile(File file) {
    state = state.copyWith(receiptQueue: [...state.receiptQueue, file]);
  }

  void removeReceiptFile(File file) {
    state = state.copyWith(
      receiptQueue: state.receiptQueue
          .where((f) => f.path != file.path)
          .toList(),
    );
  }

  void _parseCategoryFromHashtag(String description) {
    for (final e in _hashtagToSlug.entries) {
      if (description.contains(e.key)) {
        updateCategory(e.value);
        return;
      }
    }
  }

  void _fetchConversionPreview() {
    if (state.currency == params.groupCurrency) {
      state = state.copyWith(convertedPreview: null);
      return;
    }
    unawaited(() async {
      try {
        final result = await ref.read(
          convertAmountProvider(
            ConvertParams(
              from: state.currency,
              to: params.groupCurrency,
              amount: state.amount,
            ),
          ).future,
        );
        state = state.copyWith(convertedPreview: result.result);
      } catch (_) {
        state = state.copyWith(convertedPreview: null);
      }
    }());
  }

  String? _validateAmountPositive() {
    final raw = state.amount.trim();
    if (raw.isEmpty) return addExpenseAmountInvalid;
    final d = Decimal.tryParse(raw);
    if (d == null || d <= Decimal.zero) return addExpenseAmountInvalid;
    return null;
  }

  String? _validateFriendSelection() {
    if (_isGroupExpense) {
      return null;
    }
    return (state.selectedFriendUserId ?? '').isEmpty
        ? addExpenseFriendRequired
        : null;
  }

  String? validateSplits() {
    switch (state.splitMethod) {
      case 'equal':
        return null;
      case 'exact':
        return _validateExact();
      case 'percentage':
        return _validatePercentage();
      case 'shares':
        return _validateShares();
      default:
        return null;
    }
  }

  String? _validateExact() {
    final total = Decimal.tryParse(state.amount.trim());
    if (total == null) return addExpenseSplitDoesNotMatch;
    Decimal sum = Decimal.zero;
    for (final p in state.participants) {
      final d = Decimal.tryParse(p.amountOwed.trim());
      if (d == null) return addExpenseSplitDoesNotMatch;
      sum += d;
    }
    if ((sum - total).abs() >= _splitTolerance) {
      return addExpenseSplitDoesNotMatch;
    }
    return null;
  }

  String? _validatePercentage() {
    Decimal sum = Decimal.zero;
    for (final p in state.participants) {
      final d = Decimal.tryParse(p.shareValue.trim());
      if (d == null) return addExpenseSplitDoesNotMatch;
      sum += d;
    }
    final hundred = Decimal.fromInt(100);
    if ((sum - hundred).abs() >= _splitTolerance) {
      return addExpenseSplitDoesNotMatch;
    }
    return null;
  }

  String? _validateShares() {
    for (final p in state.participants) {
      final d = Decimal.tryParse(p.shareValue.trim());
      if (d == null || d <= Decimal.zero) {
        return addExpenseSplitDoesNotMatch;
      }
    }
    return null;
  }

  Map<String, dynamic> _buildBody() {
    final splits = <Map<String, dynamic>>[];
    switch (state.splitMethod) {
      case 'equal':
        for (final p in state.participants) {
          splits.add(<String, dynamic>{'user_id': p.userId});
        }
        break;
      case 'exact':
        for (final p in state.participants) {
          splits.add(<String, dynamic>{
            'user_id': p.userId,
            'amount_owed': p.amountOwed,
          });
        }
        break;
      case 'percentage':
      case 'shares':
        for (final p in state.participants) {
          splits.add(<String, dynamic>{
            'user_id': p.userId,
            'share_value': p.shareValue,
          });
        }
        break;
      default:
        for (final p in state.participants) {
          splits.add(<String, dynamic>{'user_id': p.userId});
        }
    }

    final body = <String, dynamic>{
      'paid_by': state.paidByUserId,
      'amount': state.amount,
      'currency': state.currency,
      'description': state.description,
      'category': state.category,
      'expense_date': DateFormat('yyyy-MM-dd').format(state.expenseDate),
      'split_method': state.splitMethod,
      'splits': splits,
    };
    if (params.groupId != null) {
      body['group_id'] = params.groupId;
    }
    return body;
  }

  Future<ExpenseDetailModel?> submit() async {
    final friendErr = _validateFriendSelection();
    if (friendErr != null) {
      state = state.copyWith(validationError: friendErr);
      return null;
    }

    final amountErr = _validateAmountPositive();
    if (amountErr != null) {
      state = state.copyWith(validationError: amountErr);
      return null;
    }

    final err = validateSplits();
    if (err != null) {
      state = state.copyWith(validationError: err);
      return null;
    }

    state = state.copyWith(isSubmitting: true, validationError: null);
    try {
      final body = _buildBody();
      final detail = await _repo.createExpense(body);
      final queued = List<File>.from(state.receiptQueue);
      for (final file in queued) {
        try {
          await _uploadReceipt(detail.id, file);
        } catch (_) {}
      }
      return detail;
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  Future<void> _uploadReceipt(String expenseId, File file) async {
    final contentType = _contentTypeForFile(file);
    final url = await _repo.fetchReceiptUploadUrl(
      expenseId,
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
    await _repo.confirmReceiptUpload(expenseId, url.fileKey);
  }

  static String _contentTypeForFile(File f) {
    final p = f.path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.pdf')) return 'application/pdf';
    return 'image/jpeg';
  }
}
