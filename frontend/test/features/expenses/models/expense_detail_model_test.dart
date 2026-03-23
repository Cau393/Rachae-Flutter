import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/models/split_model.dart';

void main() {
  const expenseId = '550e8400-e29b-41d4-a716-446655440001';
  const groupId = '660e8400-e29b-41d4-a716-446655440002';
  const paidById = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const createdById = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  const splitId = '770e8400-e29b-41d4-a716-446655440003';
  const splitUserId = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

  final paidByJson = <String, dynamic>{
    'id': paidById,
    'display_name': 'Payer',
    'avatar_url': null,
  };

  final createdByJson = <String, dynamic>{
    'id': createdById,
    'display_name': 'Creator',
    'avatar_url': 'https://cdn.example.com/c.png',
  };

  final splitJson = <String, dynamic>{
    'id': splitId,
    'user_id': splitUserId,
    'display_name': 'Split user',
    'avatar_url': null,
    'amount_owed': '41.83',
    'share_value': null,
    'is_settled': false,
  };

  final fullDetailJson = <String, dynamic>{
    'id': expenseId,
    'group_id': groupId,
    'paid_by': paidByJson,
    'amount': '125.50',
    'currency': 'USD',
    'exchange_rate_to_group_currency': '5.000000',
    'amount_in_group_currency': '627.50',
    'description': 'Trip',
    'category': 'viagem',
    'expense_date': '2024-02-01',
    'split_method': 'equal',
    'splits': [splitJson],
    'receipt_urls': [
      'https://cdn.example.com/r1.jpg',
      'https://cdn.example.com/r2.jpg',
    ],
    'created_by': createdByJson,
    'is_deleted': false,
    'deleted_at': null,
    'created_at': '2024-02-01T10:00:00.000Z',
    'updated_at': '2024-02-02T11:30:00.000Z',
  };

  test('fromJson maps all detail fields including splits and receiptUrls', () {
    final m = ExpenseDetailModel.fromJson(fullDetailJson);
    expect(m.id, expenseId);
    expect(m.groupId, groupId);
    expect(m.paidBy.userId, paidById);
    expect(m.amount, '125.50');
    expect(m.currency, 'USD');
    expect(m.exchangeRateToGroupCurrency, '5.000000');
    expect(m.amountInGroupCurrency, '627.50');
    expect(m.description, 'Trip');
    expect(m.category, 'viagem');
    expect(m.expenseDate, DateTime.parse('2024-02-01'));
    expect(m.splitMethod, 'equal');
    expect(m.isDeleted, isFalse);
    expect(m.createdAt, DateTime.parse('2024-02-01T10:00:00.000Z'));
    expect(m.updatedAt, DateTime.parse('2024-02-02T11:30:00.000Z'));
    expect(m.deletedAt, isNull);
    expect(m.createdBy.userId, createdById);
    expect(m.createdBy.displayName, 'Creator');
    expect(m.createdBy.avatarUrl, 'https://cdn.example.com/c.png');
    expect(m.receiptUrls, [
      'https://cdn.example.com/r1.jpg',
      'https://cdn.example.com/r2.jpg',
    ]);
    expect(m.splits, hasLength(1));
    expect(m.splits.first, isA<SplitModel>());
    expect(m.splits.first.id, splitId);
    expect(m.splits.first.userId, splitUserId);
    expect(m.splits.first.amountOwed, '41.83');
    expect(m.splits.first.shareValue, isNull);
  });

  test('amountAsMoneyAmount matches fromApiString', () {
    final m = ExpenseDetailModel.fromJson(fullDetailJson);
    expect(
      m.amountAsMoneyAmount,
      MoneyAmount.fromApiString('125.50', 'USD'),
    );
  });

  test('isAuthorizedToEdit returns true for createdBy user id', () {
    final m = ExpenseDetailModel.fromJson(fullDetailJson);
    expect(m.isAuthorizedToEdit(createdById), isTrue);
  });

  test('isAuthorizedToEdit returns false for other user id', () {
    final m = ExpenseDetailModel.fromJson(fullDetailJson);
    expect(m.isAuthorizedToEdit('ffffffff-ffff-ffff-ffff-ffffffffffff'), isFalse);
  });

  test('receipt_urls may be empty', () {
    final json = Map<String, dynamic>.from(fullDetailJson)..['receipt_urls'] = <dynamic>[];
    final m = ExpenseDetailModel.fromJson(json);
    expect(m.receiptUrls, isEmpty);
  });
}
