// ignore_for_file: library_private_types_in_public_api

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/pending_transactions_provider.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';

class _MockSettlementRepository extends Mock implements SettlementRepository {}

Map<String, dynamic> _participant(String userId) => <String, dynamic>{
  'user_id': userId,
  'display_name': 'U',
  'avatar_url': null,
};

TransactionModel _txn(String id, {required bool pending}) =>
    TransactionModel.fromJson(<String, dynamic>{
      'id': id,
      'group_id': null,
      'payer': _participant('11111111-1111-1111-1111-111111111111'),
      'receiver': _participant('22222222-2222-2222-2222-222222222222'),
      'amount': '10.00',
      'currency': 'BRL',
      'note': null,
      'is_confirmed': !pending,
      'is_disputed': false,
      'created_at': '2026-03-20T15:30:00Z',
    });

void main() {
  const otherUserId = '22222222-2222-2222-2222-222222222222';

  late _MockSettlementRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockSettlementRepository();
    container = ProviderContainer(
      overrides: [settlementRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('requests pending transactions directly from the backend', () async {
    when(
      () => mockRepo.fetchTransactionsWithUser(
        otherUserId,
        page: any(named: 'page'),
        status: any(named: 'status'),
      ),
    ).thenAnswer(
      (_) async => [_txn('01', pending: true), _txn('03', pending: true)],
    );

    final list = await container.read(
      pendingTransactionsProvider(otherUserId).future,
    );
    expect(list, hasLength(2));
    expect(list.map((t) => t.id).toList(), ['01', '03']);
    verify(
      () => mockRepo.fetchTransactionsWithUser(
        otherUserId,
        page: 1,
        status: 'pending',
      ),
    ).called(1);
  });
}
