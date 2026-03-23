import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';

void main() {
  final sampleJson = {
    'id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'group_id': 'ffffffff-ffff-ffff-ffff-ffffffffffff',
    'payer': {
      'user_id': '11111111-1111-1111-1111-111111111111',
      'display_name': 'Payer Name',
      'avatar_url': 'https://cdn/p.png',
    },
    'receiver': {
      'user_id': '22222222-2222-2222-2222-222222222222',
      'display_name': 'Receiver Name',
      'avatar_url': null,
    },
    'amount': '50.00',
    'currency': 'BRL',
    'note': 'Dinner',
    'is_confirmed': false,
    'is_disputed': false,
    'created_at': '2026-03-20T15:30:00Z',
  };

  test('fromJson parses nested payer and receiver', () {
    final m = TransactionModel.fromJson(sampleJson);
    expect(m.payer.userId, '11111111-1111-1111-1111-111111111111');
    expect(m.payer.displayName, 'Payer Name');
    expect(m.payer.avatarUrl, 'https://cdn/p.png');
    expect(m.receiver.userId, '22222222-2222-2222-2222-222222222222');
    expect(m.receiver.displayName, 'Receiver Name');
    expect(m.receiver.avatarUrl, isNull);
  });

  test('amount is String, never double', () {
    final m = TransactionModel.fromJson(sampleJson);
    expect(m.amount, isA<String>());
    expect(m.amount, isNot(isA<double>()));
  });

  test('fromJson coerces numeric amount to String via toString', () {
    final m = TransactionModel.fromJson({
      ...sampleJson,
      'amount': 50.0,
    });
    expect(m.amount, '50.0');
    expect(m.amountAsMoneyAmount.raw, '50.0');
  });

  test('isPending is true when not confirmed and not disputed', () {
    final m = TransactionModel.fromJson(sampleJson);
    expect(m.isPending, isTrue);
  });

  test('isPending is false when confirmed', () {
    final m = TransactionModel.fromJson({
      ...sampleJson,
      'is_confirmed': true,
    });
    expect(m.isPending, isFalse);
  });

  test('isPending is false when disputed', () {
    final m = TransactionModel.fromJson({
      ...sampleJson,
      'is_disputed': true,
    });
    expect(m.isPending, isFalse);
  });

  test('amountAsMoneyAmount returns MoneyAmount', () {
    final m = TransactionModel.fromJson(sampleJson);
    final amt = m.amountAsMoneyAmount;
    expect(amt, isA<MoneyAmount>());
    expect(amt.raw, '50.00');
    expect(amt.currencyCode, 'BRL');
  });

  test('groupId is null when API omits group_id', () {
    final json = Map<String, dynamic>.from(sampleJson)..remove('group_id');
    final m = TransactionModel.fromJson(json);
    expect(m.groupId, isNull);
  });

  test('note is null when absent', () {
    final json = Map<String, dynamic>.from(sampleJson)..remove('note');
    final m = TransactionModel.fromJson(json);
    expect(m.note, isNull);
  });
}
