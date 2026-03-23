import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';

class MockDio extends Mock implements Dio {}

late MockDio mockDio;
late SettlementRepository repo;

const _txnId = 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee';
const _receiverId = '22222222-2222-2222-2222-222222222222';
const _otherUserId = '33333333-3333-3333-3333-333333333333';

bool _dioHasApiError(Object e, int statusCode) {
  if (e is! DioException) return false;
  final err = e.error;
  return err is ApiException && err.statusCode == statusCode;
}

Map<String, dynamic> _participant({
  required String userId,
  String name = 'User',
  String? avatar,
}) => <String, dynamic>{
  'user_id': userId,
  'display_name': name,
  'avatar_url': avatar,
};

Map<String, dynamic> transactionJson({
  required String id,
  required String payerId,
  required String receiverId,
}) => <String, dynamic>{
  'id': id,
  'group_id': null,
  'payer': _participant(userId: payerId, name: 'Payer'),
  'receiver': _participant(userId: receiverId, name: 'Receiver'),
  'amount': '50.00',
  'currency': 'BRL',
  'note': null,
  'is_confirmed': false,
  'is_disputed': false,
  'created_at': '2026-03-20T15:30:00Z',
};

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    mockDio = MockDio();
    repo = SettlementRepository(mockDio);
  });

  group('createTransaction', () {
    test(
      'sends POST /transactions/ with correct body; null groupId and note omitted',
      () async {
        when(
          () => mockDio.post<Map<String, dynamic>>(
            '/transactions/',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              'data': transactionJson(
                id: _txnId,
                payerId: '11111111-1111-1111-1111-111111111111',
                receiverId: _receiverId,
              ),
            },
            statusCode: 201,
            requestOptions: RequestOptions(path: '/transactions/'),
          ),
        );

        final result = await repo.createTransaction(
          receiverId: _receiverId,
          amount: '50.00',
          currency: 'BRL',
        );
        expect(result, isA<TransactionModel>());
        expect(result.id, _txnId);

        verify(
          () => mockDio.post<Map<String, dynamic>>(
            '/transactions/',
            data: <String, dynamic>{
              'receiver_id': _receiverId,
              'amount': '50.00',
              'currency': 'BRL',
            },
            queryParameters: any(named: 'queryParameters'),
          ),
        ).called(1);
      },
    );

    test('includes group_id and note when provided', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/transactions/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': transactionJson(
              id: _txnId,
              payerId: '11111111-1111-1111-1111-111111111111',
              receiverId: _receiverId,
            ),
          },
          statusCode: 201,
          requestOptions: RequestOptions(path: '/transactions/'),
        ),
      );

      const groupId = 'ffffffff-ffff-ffff-ffff-ffffffffffff';
      await repo.createTransaction(
        receiverId: _receiverId,
        amount: '10.00',
        currency: 'BRL',
        groupId: groupId,
        note: 'Thanks',
      );

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/transactions/',
          data: <String, dynamic>{
            'receiver_id': _receiverId,
            'amount': '10.00',
            'currency': 'BRL',
            'group_id': groupId,
            'note': 'Thanks',
          },
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });

    test('400 response throws ApiException(400)', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/transactions/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/transactions/'),
          response: Response<void>(
            statusCode: 400,
            requestOptions: RequestOptions(path: '/transactions/'),
          ),
          type: DioExceptionType.badResponse,
          error: const ApiException(statusCode: 400, message: 'bad request'),
        ),
      );

      await expectLater(
        repo.createTransaction(
          receiverId: _receiverId,
          amount: '50.00',
          currency: 'BRL',
        ),
        throwsA(predicate((Object e) => _dioHasApiError(e, 400))),
      );
    });
  });

  group('fetchTransactionsWithUser', () {
    test('passes with_user and status through to the backend', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/transactions/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': <dynamic>[
              transactionJson(
                id: '01',
                payerId: _otherUserId,
                receiverId: '11111111-1111-1111-1111-111111111111',
              ),
            ],
            'pagination': <String, dynamic>{},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/transactions/'),
        ),
      );

      final result = await repo.fetchTransactionsWithUser(
        _otherUserId,
        status: 'pending',
      );
      expect(result, hasLength(1));
      expect(result.single.id, '01');

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/transactions/',
          queryParameters: <String, dynamic>{
            'with_user': _otherUserId,
            'page': 1,
            'limit': 20,
            'status': 'pending',
          },
        ),
      ).called(1);
    });
  });

  group('confirmTransaction', () {
    test('sends PATCH /transactions/{id}/confirm/', () async {
      when(
        () => mockDio.patch<Map<String, dynamic>>(
          '/transactions/$_txnId/confirm/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': transactionJson(
              id: _txnId,
              payerId: '11111111-1111-1111-1111-111111111111',
              receiverId: _receiverId,
            )..['is_confirmed'] = true,
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/transactions/$_txnId/confirm/',
          ),
        ),
      );

      final result = await repo.confirmTransaction(_txnId);
      expect(result.isConfirmed, isTrue);

      verify(
        () => mockDio.patch<Map<String, dynamic>>(
          '/transactions/$_txnId/confirm/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('disputeTransaction', () {
    test('sends PATCH /transactions/{id}/dispute/', () async {
      when(
        () => mockDio.patch<Map<String, dynamic>>(
          '/transactions/$_txnId/dispute/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': transactionJson(
              id: _txnId,
              payerId: '11111111-1111-1111-1111-111111111111',
              receiverId: _receiverId,
            )..['is_disputed'] = true,
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/transactions/$_txnId/dispute/',
          ),
        ),
      );

      final result = await repo.disputeTransaction(_txnId);
      expect(result.isDisputed, isTrue);

      verify(
        () => mockDio.patch<Map<String, dynamic>>(
          '/transactions/$_txnId/dispute/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });
}
