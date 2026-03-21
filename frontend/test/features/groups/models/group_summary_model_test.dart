import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';

void main() {
  const createdAt = '2025-01-15T12:30:00.000Z';

  const sampleJson = <String, dynamic>{
    'id': '11111111-1111-1111-1111-111111111111',
    'name': 'Trip',
    'type': 'trip',
    'currency': 'BRL',
    'member_count': 4,
    'your_net_balance': '-12.50',
    'created_at': createdAt,
  };

  test('fromJson maps all fields from fixture', () {
    final model = GroupSummaryModel.fromJson(sampleJson);
    expect(model.id, '11111111-1111-1111-1111-111111111111');
    expect(model.name, 'Trip');
    expect(model.type, 'trip');
    expect(model.currency, 'BRL');
    expect(model.memberCount, 4);
    expect(model.yourNetBalance, '-12.50');
    expect(model.createdAt, DateTime.parse(createdAt));
  });

  test('yourNetBalance is stored as String, not double', () {
    final model = GroupSummaryModel.fromJson(sampleJson);
    expect(model.yourNetBalance, isA<String>());
    expect(model.yourNetBalance, isNot(isA<double>()));
  });

  test('yourNetBalanceAsAmount returns MoneyAmount with correct raw and currencyCode',
      () {
    final model = GroupSummaryModel.fromJson(sampleJson);
    final amount = model.yourNetBalanceAsAmount;
    expect(amount, isA<MoneyAmount>());
    expect(amount.raw, '-12.50');
    expect(amount.currencyCode, 'BRL');
  });

  test('isNetNegative is true when your_net_balance is negative', () {
    final model = GroupSummaryModel.fromJson(sampleJson);
    expect(model.isNetNegative, isTrue);
    expect(model.isNetPositive, isFalse);
    expect(model.isNetZero, isFalse);
  });

  test('isNetPositive is true when your_net_balance is positive', () {
    final model = GroupSummaryModel.fromJson({
      ...sampleJson,
      'your_net_balance': '99.99',
    });
    expect(model.isNetPositive, isTrue);
    expect(model.isNetNegative, isFalse);
    expect(model.isNetZero, isFalse);
  });

  test('isNetZero is true when your_net_balance is zero', () {
    final model = GroupSummaryModel.fromJson({
      ...sampleJson,
      'your_net_balance': '0.00',
    });
    expect(model.isNetZero, isTrue);
    expect(model.isNetPositive, isFalse);
    expect(model.isNetNegative, isFalse);
  });

  test('fromJsonList parses a two-item list', () {
    final list = GroupSummaryModel.fromJsonList([
      sampleJson,
      {
        'id': '22222222-2222-2222-2222-222222222222',
        'name': 'Home',
        'type': 'home',
        'currency': 'USD',
        'member_count': 2,
        'your_net_balance': '0.00',
        'created_at': createdAt,
      },
    ]);
    expect(list, hasLength(2));
    expect(list[0].id, '11111111-1111-1111-1111-111111111111');
    expect(list[1].id, '22222222-2222-2222-2222-222222222222');
    expect(list[1].currency, 'USD');
  });

  test('two instances with same id are equal regardless of other fields', () {
    final a = GroupSummaryModel.fromJson(sampleJson);
    final b = GroupSummaryModel.fromJson({
      ...sampleJson,
      'name': 'Other',
      'your_net_balance': '100.00',
    });
    expect(a, equals(b));
  });

  test('two instances with different id are not equal', () {
    final a = GroupSummaryModel.fromJson(sampleJson);
    final b = GroupSummaryModel.fromJson({
      ...sampleJson,
      'id': '99999999-9999-9999-9999-999999999999',
    });
    expect(a, isNot(equals(b)));
  });

  test('fromJson coerces numeric your_net_balance to String via toString', () {
    final model = GroupSummaryModel.fromJson({
      ...sampleJson,
      'your_net_balance': -12.5,
    });
    expect(model.yourNetBalance, '-12.5');
    expect(model.yourNetBalance, isA<String>());
    expect(model.yourNetBalanceAsAmount.raw, '-12.5');
  });
}
