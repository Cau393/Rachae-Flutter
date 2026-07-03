import 'dart:io';

import 'package:flutter/foundation.dart';

import 'package:frontend/core/currency/default_currency.dart';

@immutable
class SplitParticipant {
  const SplitParticipant({
    required this.userId,
    required this.displayName,
    this.amountOwed = '',
    this.shareValue = '',
  });

  final String userId;
  final String displayName;
  final String amountOwed;
  final String shareValue;

  SplitParticipant copyWith({
    String? userId,
    String? displayName,
    String? amountOwed,
    String? shareValue,
  }) {
    return SplitParticipant(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      amountOwed: amountOwed ?? this.amountOwed,
      shareValue: shareValue ?? this.shareValue,
    );
  }
}

@immutable
class AddExpenseFormState {
  AddExpenseFormState({
    this.amount = '',
    this.currency = kDefaultCurrencyCode,
    this.description = '',
    this.category = 'geral',
    DateTime? expenseDate,
    this.splitMethod = 'equal',
    this.paidByUserId = '',
    this.availablePeople = const [],
    this.participants = const [],
    this.selectedFriendUserId,
    this.receiptQueue = const [],
    this.convertedPreview,
    this.isSubmitting = false,
    this.validationError,
    this.failedReceiptCount = 0,
  }) : expenseDate = expenseDate ?? DateTime.now();

  final String amount;
  final String currency;
  final String description;
  final String category;
  final DateTime expenseDate;
  final String splitMethod;
  final String paidByUserId;
  final List<SplitParticipant> availablePeople;
  final List<SplitParticipant> participants;
  final String? selectedFriendUserId;
  final List<File> receiptQueue;
  final String? convertedPreview;
  final bool isSubmitting;
  final String? validationError;

  /// Receipts that failed to upload after the expense itself saved
  /// successfully. Surfaced to the user via a partial-failure snackbar.
  final int failedReceiptCount;

  static const _sentinel = Object();

  AddExpenseFormState copyWith({
    String? amount,
    String? currency,
    String? description,
    String? category,
    DateTime? expenseDate,
    String? splitMethod,
    String? paidByUserId,
    List<SplitParticipant>? availablePeople,
    List<SplitParticipant>? participants,
    Object? selectedFriendUserId = _sentinel,
    List<File>? receiptQueue,
    Object? convertedPreview = _sentinel,
    bool? isSubmitting,
    Object? validationError = _sentinel,
    int? failedReceiptCount,
  }) {
    return AddExpenseFormState(
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      description: description ?? this.description,
      category: category ?? this.category,
      expenseDate: expenseDate ?? this.expenseDate,
      splitMethod: splitMethod ?? this.splitMethod,
      paidByUserId: paidByUserId ?? this.paidByUserId,
      availablePeople: availablePeople ?? this.availablePeople,
      participants: participants ?? this.participants,
      selectedFriendUserId: selectedFriendUserId == _sentinel
          ? this.selectedFriendUserId
          : selectedFriendUserId as String?,
      receiptQueue: receiptQueue ?? this.receiptQueue,
      convertedPreview: convertedPreview == _sentinel
          ? this.convertedPreview
          : convertedPreview as String?,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      validationError: validationError == _sentinel
          ? this.validationError
          : validationError as String?,
      failedReceiptCount: failedReceiptCount ?? this.failedReceiptCount,
    );
  }
}
