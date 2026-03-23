import 'package:flutter/foundation.dart';
import 'package:frontend/core/currency/money_amount.dart';

@immutable
class ParticipantInfo {
  const ParticipantInfo({
    required this.userId,
    required this.displayName,
    this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String? avatarUrl;

  factory ParticipantInfo.fromJson(Map<String, dynamic> json) {
    return ParticipantInfo(
      userId: json['user_id'].toString(),
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }
}

@immutable
class TransactionModel {
  const TransactionModel({
    required this.id,
    this.groupId,
    required this.payer,
    required this.receiver,
    required this.amount,
    required this.currency,
    this.note,
    this.proofUrls = const [],
    required this.isConfirmed,
    required this.isDisputed,
    required this.createdAt,
  });

  final String id;
  final String? groupId;
  final ParticipantInfo payer;
  final ParticipantInfo receiver;
  final String amount;
  final String currency;
  final String? note;
  final List<String> proofUrls;
  final bool isConfirmed;
  final bool isDisputed;
  final DateTime createdAt;

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final proofRaw = json['proof_urls'] as List<dynamic>? ?? const <dynamic>[];
    return TransactionModel(
      id: json['id'].toString(),
      groupId: json['group_id']?.toString(),
      payer: ParticipantInfo.fromJson(
        Map<String, dynamic>.from(json['payer'] as Map),
      ),
      receiver: ParticipantInfo.fromJson(
        Map<String, dynamic>.from(json['receiver'] as Map),
      ),
      amount: json['amount'].toString(),
      currency: json['currency'] as String,
      note: json['note'] as String?,
      proofUrls: proofRaw.map((e) => e.toString()).toList(),
      isConfirmed: json['is_confirmed'] as bool,
      isDisputed: json['is_disputed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  MoneyAmount get amountAsMoneyAmount =>
      MoneyAmount.fromApiString(amount, currency);

  bool get isPending => !isConfirmed && !isDisputed;
}
