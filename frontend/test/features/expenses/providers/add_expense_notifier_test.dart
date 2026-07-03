// ignore_for_file: library_private_types_in_public_api

import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/models/expense_form_state.dart';
import 'package:frontend/features/expenses/providers/add_expense_notifier.dart';
import 'package:frontend/features/expenses/providers/expense_repository_provider.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';

class _MockExpenseRepository extends Mock implements ExpenseRepository {}

GroupMemberModel _member(String uid, String name) => GroupMemberModel(
  userId: uid,
  displayName: name,
  avatarUrl: null,
  role: 'MEMBER',
  joinedAt: DateTime.parse('2025-01-01T00:00:00.000Z'),
  invitedBy: null,
);

ExpenseDetailModel _expenseDetail(String id) =>
    ExpenseDetailModel.fromJson(<String, dynamic>{
      'id': id,
      'group_id': '660e8400-e29b-41d4-a716-446655440002',
      'paid_by': <String, dynamic>{
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'display_name': 'P',
        'avatar_url': null,
      },
      'amount': '10.00',
      'currency': 'BRL',
      'exchange_rate_to_group_currency': '1.000000',
      'amount_in_group_currency': '10.00',
      'description': 'D',
      'category': 'geral',
      'expense_date': '2024-01-10',
      'split_method': 'equal',
      'splits': <dynamic>[],
      'receipt_urls': <dynamic>[],
      'created_by': <String, dynamic>{
        'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
        'display_name': 'C',
        'avatar_url': null,
      },
      'is_deleted': false,
      'deleted_at': null,
      'created_at': '2024-01-10T10:00:00.000Z',
      'updated_at': '2024-01-10T10:00:00.000Z',
    });

void main() {
  const uid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const otherId = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
  const groupId = '660e8400-e29b-41d4-a716-446655440002';

  late _MockExpenseRepository mockRepo;
  late ProviderContainer container;

  late AddExpenseParams params;
  late AddExpenseParams personalParams;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockRepo = _MockExpenseRepository();
    params = AddExpenseParams(
      groupId: groupId,
      currentUserId: uid,
      backendUserId: uid,
      members: [_member(uid, 'Me'), _member(otherId, 'Other')],
      groupCurrency: 'BRL',
    );
    personalParams = AddExpenseParams(
      groupId: null,
      currentUserId: uid,
      backendUserId: uid,
      members: [_member(uid, 'Me'), _member(otherId, 'Other')],
      groupCurrency: 'BRL',
    );
    container = ProviderContainer(
      overrides: [expenseRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  AddExpenseNotifier notifier() =>
      container.read(addExpenseNotifierProvider(params).notifier);

  AddExpenseFormState state() =>
      container.read(addExpenseNotifierProvider(params));

  AddExpenseNotifier personalNotifier() =>
      container.read(addExpenseNotifierProvider(personalParams).notifier);

  AddExpenseFormState personalState() =>
      container.read(addExpenseNotifierProvider(personalParams));

  test('initial state has isSubmitting false and validationError null', () {
    expect(state().isSubmitting, isFalse);
    expect(state().validationError, isNull);
    expect(state().availablePeople, hasLength(2));
  });

  test('personal initial state keeps only current user in participants', () {
    expect(personalState().availablePeople, hasLength(2));
    expect(personalState().participants, hasLength(1));
    expect(personalState().participants.single.userId, uid);
    expect(personalState().selectedFriendUserId, isNull);
  });

  test("updateDescription('#comida jantar') sets category to comida", () {
    notifier().updateDescription('#comida jantar');
    expect(state().category, 'comida');
  });

  test('validateSplits exact mismatch returns addExpenseSplitDoesNotMatch', () {
    final n = notifier();
    n.updateSplitMethod('exact');
    n.updateAmount('100.00');
    n.updateParticipantAmount(uid, '40.00');
    n.updateParticipantAmount(otherId, '50.00');
    expect(n.validateSplits(), addExpenseSplitDoesNotMatch);
  });

  test('validateSplits percentage sum not 100 returns error key', () {
    final n = notifier();
    n.updateSplitMethod('percentage');
    n.updateParticipantShare(uid, '50');
    n.updateParticipantShare(otherId, '40');
    expect(n.validateSplits(), addExpenseSplitDoesNotMatch);
  });

  test('validateSplits equal always returns null', () {
    final n = notifier();
    n.updateSplitMethod('equal');
    expect(n.validateSplits(), isNull);
  });

  test(
    'submit with validation error sets validationError and does not call repo',
    () async {
      when(
        () => mockRepo.createExpense(any()),
      ).thenAnswer((_) async => _expenseDetail('e-new'));

      final n = notifier();
      n.updateSplitMethod('exact');
      n.updateAmount('100.00');
      n.updateParticipantAmount(uid, '10.00');
      n.updateParticipantAmount(otherId, '10.00');

      final result = await n.submit();
      expect(result, isNull);
      expect(state().validationError, addExpenseSplitDoesNotMatch);
      verifyNever(() => mockRepo.createExpense(any()));
    },
  );

  test(
    'submit with empty amount sets addExpenseAmountInvalid and does not call repo',
    () async {
      when(
        () => mockRepo.createExpense(any()),
      ).thenAnswer((_) async => _expenseDetail('e-new'));

      final n = notifier();
      n.updateSplitMethod('equal');
      n.updateAmount('');
      n.updateDescription('Lunch');

      final result = await n.submit();
      expect(result, isNull);
      expect(state().validationError, addExpenseAmountInvalid);
      verifyNever(() => mockRepo.createExpense(any()));
    },
  );

  test(
    'personal submit without friend sets addExpenseFriendRequired',
    () async {
      final result = await personalNotifier().submit();
      expect(result, isNull);
      expect(personalState().validationError, addExpenseFriendRequired);
      verifyNever(() => mockRepo.createExpense(any()));
    },
  );

  test(
    'personal friend selection adds friend as participant and keeps payer valid',
    () {
      final n = personalNotifier();
      n.updateSelectedFriend(otherId);

      expect(personalState().selectedFriendUserId, otherId);
      expect(personalState().participants.map((p) => p.userId).toList(), [
        uid,
        otherId,
      ]);
      expect(personalState().paidByUserId, uid);
    },
  );

  test(
    'personal submit includes only current user and selected friend',
    () async {
      when(
        () => mockRepo.createExpense(any()),
      ).thenAnswer((_) async => _expenseDetail('e5'));

      final n = personalNotifier();
      n.updateSelectedFriend(otherId);
      n.updateSplitMethod('equal');
      n.updateAmount('30.00');
      n.updateDescription('Dinner');
      n.updatePaidBy(otherId);

      await n.submit();

      final captured =
          verify(() => mockRepo.createExpense(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(captured['group_id'], isNull);
      expect(captured['paid_by'], otherId);
      expect(captured['splits'], [
        <String, dynamic>{'user_id': uid},
        <String, dynamic>{'user_id': otherId},
      ]);
    },
  );

  test('submit with valid form calls createExpense once', () async {
    when(
      () => mockRepo.createExpense(any()),
    ).thenAnswer((_) async => _expenseDetail('e-new'));

    final n = notifier();
    n.updateSplitMethod('equal');
    n.updateAmount('100.00');
    n.updateDescription('Lunch');

    final result = await n.submit();
    expect(result, isNotNull);
    verify(() => mockRepo.createExpense(any())).called(1);
  });

  test('submit builds equal splits with user_id only', () async {
    when(
      () => mockRepo.createExpense(any()),
    ).thenAnswer((_) async => _expenseDetail('e1'));

    final n = notifier();
    n.updateSplitMethod('equal');
    n.updateAmount('50.00');
    n.updateDescription('x');

    await n.submit();

    final captured =
        verify(() => mockRepo.createExpense(captureAny())).captured.single
            as Map<String, dynamic>;
    expect(captured['split_method'], 'equal');
    final splits = captured['splits'] as List<dynamic>;
    expect(splits, hasLength(2));
    expect(splits[0], <String, dynamic>{'user_id': uid});
    expect(splits[1], <String, dynamic>{'user_id': otherId});
    expect(captured['group_id'], groupId);
    expect(
      captured['expense_date'],
      DateFormat('yyyy-MM-dd').format(state().expenseDate),
    );
  });

  test('submit builds exact splits with amount_owed', () async {
    when(
      () => mockRepo.createExpense(any()),
    ).thenAnswer((_) async => _expenseDetail('e2'));

    final n = notifier();
    n.updateSplitMethod('exact');
    n.updateAmount('100.00');
    n.updateParticipantAmount(uid, '60.00');
    n.updateParticipantAmount(otherId, '40.00');

    await n.submit();

    final captured =
        verify(() => mockRepo.createExpense(captureAny())).captured.single
            as Map<String, dynamic>;
    final splits = captured['splits'] as List<dynamic>;
    expect(splits[0], <String, dynamic>{
      'user_id': uid,
      'amount_owed': '60.00',
    });
    expect(splits[1], <String, dynamic>{
      'user_id': otherId,
      'amount_owed': '40.00',
    });
  });

  test('submit builds percentage splits with share_value', () async {
    when(
      () => mockRepo.createExpense(any()),
    ).thenAnswer((_) async => _expenseDetail('e3'));

    final n = notifier();
    n.updateSplitMethod('percentage');
    n.updateAmount('200.00');
    n.updateParticipantShare(uid, '50');
    n.updateParticipantShare(otherId, '50');

    await n.submit();

    final captured =
        verify(() => mockRepo.createExpense(captureAny())).captured.single
            as Map<String, dynamic>;
    expect(captured['split_method'], 'percentage');
    final splits = captured['splits'] as List<dynamic>;
    expect(splits[0], <String, dynamic>{'user_id': uid, 'share_value': '50'});
    expect(splits[1], <String, dynamic>{
      'user_id': otherId,
      'share_value': '50',
    });
  });

  test('submit builds shares splits with share_value', () async {
    when(
      () => mockRepo.createExpense(any()),
    ).thenAnswer((_) async => _expenseDetail('e4'));

    final n = notifier();
    n.updateSplitMethod('shares');
    n.updateAmount('90.00');
    n.updateParticipantShare(uid, '2');
    n.updateParticipantShare(otherId, '1');

    await n.submit();

    final captured =
        verify(() => mockRepo.createExpense(captureAny())).captured.single
            as Map<String, dynamic>;
    expect(captured['split_method'], 'shares');
    final splits = captured['splits'] as List<dynamic>;
    expect(splits[0]['share_value'], '2');
    expect(splits[1]['share_value'], '1');
  });

  test(
    'receipt upload failure leaves isSubmitting false and completes submit',
    () async {
      when(
        () => mockRepo.createExpense(any()),
      ).thenAnswer((_) async => _expenseDetail('exp-with-receipt'));
      when(
        () => mockRepo.fetchReceiptUploadUrl(
          any(),
          contentType: any(named: 'contentType'),
        ),
      ).thenThrow(Exception('network'));

      final tmp = File(
        '${Directory.systemTemp.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      addTearDown(() {
        if (tmp.existsSync()) tmp.deleteSync();
      });
      await tmp.writeAsBytes(<int>[1, 2, 3]);

      final n = notifier();
      n.updateSplitMethod('equal');
      n.updateAmount('25.00');
      n.addReceiptFile(tmp);

      final result = await n.submit();

      expect(result, isNotNull);
      expect(state().isSubmitting, isFalse);
      expect(state().failedReceiptCount, 1);
      verify(() => mockRepo.createExpense(any())).called(1);
      verify(
        () => mockRepo.fetchReceiptUploadUrl(
          'exp-with-receipt',
          contentType: any(named: 'contentType'),
        ),
      ).called(1);
      verifyNever(() => mockRepo.confirmReceiptUpload(any(), any()));
    },
  );

  test('successful submit resets failedReceiptCount to zero', () async {
    when(
      () => mockRepo.createExpense(any()),
    ).thenAnswer((_) async => _expenseDetail('e-no-receipts'));

    final n = notifier();
    n.updateSplitMethod('equal');
    n.updateAmount('20.00');

    await n.submit();

    expect(state().failedReceiptCount, 0);
  });
}
