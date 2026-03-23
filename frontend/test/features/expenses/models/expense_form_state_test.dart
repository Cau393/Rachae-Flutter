import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/expenses/models/expense_form_state.dart';

void main() {
  test(
    'default AddExpenseFormState has splitMethod equal and category geral',
    () {
      final state = AddExpenseFormState();
      expect(state.splitMethod, 'equal');
      expect(state.category, 'geral');
      expect(state.amount, '');
      expect(state.currency, 'BRL');
      expect(state.description, '');
      expect(state.paidByUserId, '');
      expect(state.availablePeople, isEmpty);
      expect(state.participants, isEmpty);
      expect(state.selectedFriendUserId, isNull);
      expect(state.receiptQueue, isEmpty);
      expect(state.convertedPreview, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.validationError, isNull);
    },
  );

  test('default expenseDate is calendar-today', () {
    final state = AddExpenseFormState();
    final now = DateTime.now();
    expect(state.expenseDate.year, now.year);
    expect(state.expenseDate.month, now.month);
    expect(state.expenseDate.day, now.day);
  });

  test('copyWith changes only specified fields', () {
    final base = AddExpenseFormState(
      amount: '50.00',
      currency: 'USD',
      splitMethod: 'exact',
      validationError: 'err',
    );
    final next = base.copyWith(amount: '75.00');
    expect(next.amount, '75.00');
    expect(next.currency, 'USD');
    expect(next.splitMethod, 'exact');
    expect(next.validationError, 'err');
  });

  test('three equal participants preserves length and amount', () {
    final p1 = SplitParticipant(
      userId: 'u1',
      displayName: 'A',
      amountOwed: '',
      shareValue: '',
    );
    final p2 = SplitParticipant(
      userId: 'u2',
      displayName: 'B',
      amountOwed: '',
      shareValue: '',
    );
    final p3 = SplitParticipant(
      userId: 'u3',
      displayName: 'C',
      amountOwed: '',
      shareValue: '',
    );
    final state = AddExpenseFormState(
      amount: '100.00',
      splitMethod: 'equal',
      availablePeople: [p1, p2, p3],
      participants: [p1, p2, p3],
    );
    expect(state.availablePeople, hasLength(3));
    expect(state.participants, hasLength(3));
    expect(state.amount, '100.00');
  });

  test('SplitParticipant copyWith preserves unspecified fields', () {
    final p = SplitParticipant(
      userId: 'u1',
      displayName: 'Ada',
      amountOwed: '10.00',
      shareValue: '50',
    );
    final q = p.copyWith(amountOwed: '20.00');
    expect(q.userId, 'u1');
    expect(q.displayName, 'Ada');
    expect(q.amountOwed, '20.00');
    expect(q.shareValue, '50');
  });

  test('receiptQueue can hold File instances', () {
    final f = File('/tmp/receipt.jpg');
    final state = AddExpenseFormState(receiptQueue: [f]);
    expect(state.receiptQueue, hasLength(1));
    expect(state.receiptQueue.single.path, '/tmp/receipt.jpg');
  });
}
