import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/expenses/models/split_model.dart';

void main() {
  const splitJson = <String, dynamic>{
    'id': '770e8400-e29b-41d4-a716-446655440003',
    'user_id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
    'display_name': 'Ada',
    'avatar_url': null,
    'amount_owed': '33.34',
    'share_value': '33.3333',
    'is_settled': true,
  };

  test('fromJson maps all fields; amountOwed and shareValue are String when present', () {
    final m = SplitModel.fromJson(splitJson);
    expect(m.id, '770e8400-e29b-41d4-a716-446655440003');
    expect(m.userId, 'cccccccc-cccc-cccc-cccc-cccccccccccc');
    expect(m.displayName, 'Ada');
    expect(m.avatarUrl, isNull);
    expect(m.amountOwed, isA<String>());
    expect(m.amountOwed, '33.34');
    expect(m.shareValue, isA<String>());
    expect(m.shareValue, '33.3333');
    expect(m.isSettled, isTrue);
  });

  test('fromJson coerces numeric amount_owed and share_value to String', () {
    final json = Map<String, dynamic>.from(splitJson)
      ..['amount_owed'] = 10.5
      ..['share_value'] = 25.25;
    final m = SplitModel.fromJson(json);
    expect(m.amountOwed, '10.5');
    expect(m.shareValue, '25.25');
  });

  test('share_value null maps to null shareValue', () {
    final json = Map<String, dynamic>.from(splitJson)..['share_value'] = null;
    final m = SplitModel.fromJson(json);
    expect(m.shareValue, isNull);
  });

  test('amountOwedAsMoneyAmount returns MoneyAmount for BRL', () {
    final m = SplitModel.fromJson(splitJson);
    final amt = m.amountOwedAsMoneyAmount('BRL');
    expect(amt, isA<MoneyAmount>());
    expect(amt.raw, '33.34');
    expect(amt.currencyCode, 'BRL');
  });
}
