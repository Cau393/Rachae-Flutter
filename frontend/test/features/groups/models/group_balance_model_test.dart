import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/groups/models/group_balance_model.dart';

void main() {
  const sampleJson = <String, dynamic>{
    'user_id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'display_name': 'Carl',
    'net_balance': '45.25',
  };

  test('fromJson maps user_id, display_name, net_balance', () {
    final m = GroupBalanceModel.fromJson(sampleJson);
    expect(m.userId, 'cccccccc-cccc-cccc-cccc-cccccccccccc');
    expect(m.displayName, 'Carl');
    expect(m.netBalance, '45.25');
  });

  test('net_balance is stored as String, not double', () {
    final m = GroupBalanceModel.fromJson(sampleJson);
    expect(m.netBalance, isA<String>());
    expect(m.netBalance, isNot(isA<double>()));
  });

  test('fromJson coerces numeric net_balance to String', () {
    final m = GroupBalanceModel.fromJson({
      ...sampleJson,
      'net_balance': -10.5,
    });
    expect(m.netBalance, '-10.5');
    expect(m.netBalance, isA<String>());
  });

  test('netBalanceAsAmount returns MoneyAmount.fromApiString(netBalance, currency)',
      () {
    final m = GroupBalanceModel.fromJson(sampleJson);
    final amount = m.netBalanceAsAmount('BRL');
    expect(amount, isA<MoneyAmount>());
    expect(amount.raw, '45.25');
    expect(amount.currencyCode, 'BRL');
  });
}
