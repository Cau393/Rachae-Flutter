import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/currency/money_amount.dart';
import 'package:frontend/features/dashboard/models/activity_item_model.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';

const expenseActivityJson = {
  'id': '550e8400-e29b-41d4-a716-446655440001',
  'type': 'expense',
  'group_id': null,
  'group_name': null,
  'description': 'Dinner',
  'amount': '60.00',
  'currency': 'BRL',
  'paid_by_id': 'user-alice',
  'paid_by_name': 'Alice',
  'created_at': '2024-01-15T12:00:00.000Z',
};

const transactionActivityJson = {
  'id': '550e8400-e29b-41d4-a716-446655440002',
  'type': 'transaction',
  'group_id': null,
  'group_name': null,
  'amount': '30.00',
  'currency': 'BRL',
  'payer_id': 'payer-bob',
  'payer_name': 'Bob',
  'receiver_id': 'receiver-carol',
  'receiver_name': 'Carol',
  'note': null,
  'is_confirmed': false,
  'created_at': '2024-01-16T14:30:00.000Z',
};

void main() {
  test('fromJson returns ExpenseActivity when type is expense', () {
    final item = ActivityItemModel.fromJson(expenseActivityJson);
    expect(item, isA<ExpenseActivity>());
  });

  test('fromJson returns TransactionActivity when type is transaction', () {
    final item = ActivityItemModel.fromJson(transactionActivityJson);
    expect(item, isA<TransactionActivity>());
  });

  test('ExpenseActivity has non-null description and paidByName', () {
    final item =
        ActivityItemModel.fromJson(expenseActivityJson) as ExpenseActivity;
    expect(item.description, 'Dinner');
    expect(item.paidByName, 'Alice');
    expect(item.groupName, isNull);
  });

  test(
    'TransactionActivity has non-null payerName and receiverName and isConfirmed from JSON',
    () {
      final item =
          ActivityItemModel.fromJson(transactionActivityJson)
              as TransactionActivity;
      expect(item.payerName, 'Bob');
      expect(item.receiverName, 'Carol');
      expect(item.isConfirmed, isFalse);
    },
  );

  test('amount is stored as String on ExpenseActivity', () {
    final item =
        ActivityItemModel.fromJson(expenseActivityJson) as ExpenseActivity;
    expect(item.amount, isA<String>());
    expect(item.amount, isNot(isA<double>()));
    expect(item.amount, '60.00');
  });

  test('amount is stored as String on TransactionActivity', () {
    final item =
        ActivityItemModel.fromJson(transactionActivityJson)
            as TransactionActivity;
    expect(item.amount, isA<String>());
    expect(item.amount, isNot(isA<double>()));
    expect(item.amount, '30.00');
  });

  test(
    'amountAsMoneyAmount returns MoneyAmount with correct raw and currencyCode',
    () {
      final expense =
          ActivityItemModel.fromJson(expenseActivityJson) as ExpenseActivity;
      final txn =
          ActivityItemModel.fromJson(transactionActivityJson)
              as TransactionActivity;

      final expenseAmount = expense.amountAsMoneyAmount;
      expect(expenseAmount, isA<MoneyAmount>());
      expect(expenseAmount.raw, '60.00');
      expect(expenseAmount.currencyCode, 'BRL');

      final txnAmount = txn.amountAsMoneyAmount;
      expect(txnAmount.raw, '30.00');
      expect(txnAmount.currencyCode, 'BRL');
    },
  );

  test('createdAt is parsed from created_at', () {
    final expense =
        ActivityItemModel.fromJson(expenseActivityJson) as ExpenseActivity;
    expect(expense.createdAt, DateTime.parse('2024-01-15T12:00:00.000Z'));
    final txn =
        ActivityItemModel.fromJson(transactionActivityJson)
            as TransactionActivity;
    expect(txn.createdAt, DateTime.parse('2024-01-16T14:30:00.000Z'));
  });

  test('fromJsonList preserves order for mixed expense then transaction', () {
    final list = ActivityItemModel.fromJsonList([
      expenseActivityJson,
      transactionActivityJson,
    ]);
    expect(list, hasLength(2));
    expect(list[0], isA<ExpenseActivity>());
    expect(list[1], isA<TransactionActivity>());
  });

  test('fromJsonList preserves order for mixed transaction then expense', () {
    final list = ActivityItemModel.fromJsonList([
      transactionActivityJson,
      expenseActivityJson,
    ]);
    expect(list, hasLength(2));
    expect(list[0], isA<TransactionActivity>());
    expect(list[1], isA<ExpenseActivity>());
  });

  test('fromJson with unknown type throws ArgumentError', () {
    expect(
      () => ActivityItemModel.fromJson({
        'id': 'unknown-id',
        'type': 'unknown',
        'amount': '1.00',
        'currency': 'BRL',
        'created_at': '2024-01-01T00:00:00.000Z',
      }),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('ExpenseActivity.fromExpenseListModel maps list fields', () {
    final m = ExpenseListModel.fromJson(<String, dynamic>{
      'id': 'e1',
      'group_id': 'g1',
      'paid_by': <String, dynamic>{
        'id': 'u1',
        'display_name': 'Sam',
        'avatar_url': null,
      },
      'amount': '12.00',
      'currency': 'BRL',
      'amount_in_group_currency': '12.00',
      'description': 'Coffee',
      'category': 'comida',
      'expense_date': '2024-02-01',
      'split_method': 'equal',
      'split_count': 1,
      'is_deleted': false,
      'created_at': '2024-02-01T10:00:00.000Z',
    });
    final a = ExpenseActivity.fromExpenseListModel(m);
    expect(a.id, 'e1');
    expect(a.type, 'expense');
    expect(a.groupId, 'g1');
    expect(a.groupName, isNull);
    expect(a.description, 'Coffee');
    expect(a.paidById, 'u1');
    expect(a.paidByName, 'Sam');
    expect(a.amountAsMoneyAmount.raw, '12.00');
    expect(a.amountAsMoneyAmount.currencyCode, 'BRL');
  });
}
