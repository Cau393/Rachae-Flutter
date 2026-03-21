import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/groups/models/settlement_suggestion_model.dart';

void main() {
  const sampleJson = <String, dynamic>{
    'payer_id': 'dddddddd-dddd-dddd-dddd-dddddddddddd',
    'payer_name': 'Dana',
    'receiver_id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
    'receiver_name': 'Eve',
    'amount': '30.00',
    'currency': 'BRL',
  };

  test('fromJson maps all fields including currency', () {
    final m = SettlementSuggestionModel.fromJson(sampleJson);
    expect(m.payerId, 'dddddddd-dddd-dddd-dddd-dddddddddddd');
    expect(m.payerName, 'Dana');
    expect(m.receiverId, 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee');
    expect(m.receiverName, 'Eve');
    expect(m.amount, '30.00');
    expect(m.currency, 'BRL');
  });

  test('amount is stored as String, not double', () {
    final m = SettlementSuggestionModel.fromJson(sampleJson);
    expect(m.amount, isA<String>());
    expect(m.amount, isNot(isA<double>()));
  });

  test('fromJson coerces numeric amount to String', () {
    final m = SettlementSuggestionModel.fromJson({
      ...sampleJson,
      'amount': 42.5,
    });
    expect(m.amount, '42.5');
    expect(m.amount, isA<String>());
  });

  test('amountAsMoneyAmount matches MoneyAmount for raw and currency', () {
    final m = SettlementSuggestionModel.fromJson(sampleJson);
    final amt = m.amountAsMoneyAmount;
    expect(amt, isA<MoneyAmount>());
    expect(amt.raw, '30.00');
    expect(amt.currencyCode, 'BRL');
  });
}
