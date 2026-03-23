import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';

void main() {
  const expenseId = '550e8400-e29b-41d4-a716-446655440001';
  const groupId = '660e8400-e29b-41d4-a716-446655440002';
  const paidById = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';

  final paidByJson = <String, dynamic>{
    'id': paidById,
    'display_name': 'Ada',
    'avatar_url': null,
  };

  final fullListJson = <String, dynamic>{
    'id': expenseId,
    'group_id': groupId,
    'paid_by': paidByJson,
    'amount': '125.50',
    'currency': 'BRL',
    'amount_in_group_currency': '125.50',
    'description': 'Groceries',
    'category': 'comida',
    'expense_date': '2024-01-15',
    'split_method': 'equal',
    'split_count': 3,
    'is_deleted': false,
    'created_at': '2024-01-15T12:00:00.000Z',
  };

  test('fromJson maps all fields; amount and amountInGroupCurrency are String', () {
    final m = ExpenseListModel.fromJson(fullListJson);
    expect(m.id, expenseId);
    expect(m.groupId, groupId);
    expect(m.paidBy.userId, paidById);
    expect(m.paidBy.displayName, 'Ada');
    expect(m.paidBy.avatarUrl, isNull);
    expect(m.amount, isA<String>());
    expect(m.amount, '125.50');
    expect(m.currency, 'BRL');
    expect(m.amountInGroupCurrency, isA<String>());
    expect(m.amountInGroupCurrency, '125.50');
    expect(m.description, 'Groceries');
    expect(m.category, 'comida');
    expect(m.expenseDate, DateTime.parse('2024-01-15'));
    expect(m.splitMethod, 'equal');
    expect(m.splitCount, 3);
    expect(m.isDeleted, isFalse);
    expect(m.createdAt, DateTime.parse('2024-01-15T12:00:00.000Z'));
  });

  test('fromJson coerces numeric amount and amount_in_group_currency to String', () {
    final json = Map<String, dynamic>.from(fullListJson)
      ..['amount'] = 99.99
      ..['amount_in_group_currency'] = 100.01;
    final m = ExpenseListModel.fromJson(json);
    expect(m.amount, '99.99');
    expect(m.amountInGroupCurrency, '100.01');
    expect(m.amount, isNot(isA<double>()));
  });

  test('paid_by maps avatar_url when present', () {
    final json = Map<String, dynamic>.from(fullListJson);
    json['paid_by'] = {
      'id': paidById,
      'display_name': 'Ada',
      'avatar_url': 'https://cdn.example.com/a.png',
    };
    final m = ExpenseListModel.fromJson(json);
    expect(m.paidBy.avatarUrl, 'https://cdn.example.com/a.png');
  });

  test('amountAsMoneyAmount returns MoneyAmount with raw and currencyCode', () {
    final m = ExpenseListModel.fromJson(fullListJson);
    final amt = m.amountAsMoneyAmount;
    expect(amt, isA<MoneyAmount>());
    expect(amt.raw, '125.50');
    expect(amt.currencyCode, 'BRL');
  });

  test('equality is by id only', () {
    final a = ExpenseListModel.fromJson(fullListJson);
    final b = ExpenseListModel.fromJson(fullListJson);
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));
  });

  test('group_id null maps to null groupId', () {
    final json = Map<String, dynamic>.from(fullListJson)..['group_id'] = null;
    final m = ExpenseListModel.fromJson(json);
    expect(m.groupId, isNull);
  });
}
