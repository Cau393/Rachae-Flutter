// ignore_for_file: library_private_types_in_public_api

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/expenses/models/expense_detail_model.dart';
import 'package:frontend/features/expenses/models/expense_list_model.dart';
import 'package:frontend/features/expenses/repositories/expense_repository.dart';

class _MockDio extends Mock implements Dio {}

late _MockDio mockDio;
late ExpenseRepository repo;

const _expenseId = '550e8400-e29b-41d4-a716-446655440001';
const _groupId = '660e8400-e29b-41d4-a716-446655440002';
const _paidById = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
const _createdById = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
const _createdAt = '2024-02-01T10:00:00.000Z';
const _updatedAt = '2024-02-02T11:30:00.000Z';

Map<String, dynamic> _paidBy() => <String, dynamic>{
      'id': _paidById,
      'display_name': 'Payer',
      'avatar_url': null,
    };

Map<String, dynamic> _createdBy() => <String, dynamic>{
      'id': _createdById,
      'display_name': 'Creator',
      'avatar_url': null,
    };

Map<String, dynamic> _split() => <String, dynamic>{
      'id': '770e8400-e29b-41d4-a716-446655440003',
      'user_id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
      'display_name': 'Split user',
      'avatar_url': null,
      'amount_owed': '41.83',
      'share_value': null,
      'is_settled': false,
    };

Map<String, dynamic> expenseListItemJson(String id) => <String, dynamic>{
      'id': id,
      'group_id': _groupId,
      'paid_by': _paidBy(),
      'amount': '50.00',
      'currency': 'BRL',
      'amount_in_group_currency': '50.00',
      'description': 'Item',
      'category': 'geral',
      'expense_date': '2024-01-15',
      'split_method': 'equal',
      'split_count': 2,
      'is_deleted': false,
      'created_at': _createdAt,
    };

Map<String, dynamic> expenseDetailJson() => <String, dynamic>{
      'id': _expenseId,
      'group_id': _groupId,
      'paid_by': _paidBy(),
      'amount': '125.50',
      'currency': 'BRL',
      'exchange_rate_to_group_currency': '1.000000',
      'amount_in_group_currency': '125.50',
      'description': 'Trip',
      'category': 'viagem',
      'expense_date': '2024-02-01',
      'split_method': 'equal',
      'splits': [_split()],
      'receipt_urls': <String>['https://cdn.example.com/r1.jpg'],
      'created_by': _createdBy(),
      'is_deleted': false,
      'deleted_at': null,
      'created_at': _createdAt,
      'updated_at': _updatedAt,
    };

bool _dioHasApiError(Object e, int statusCode) {
  if (e is! DioException) return false;
  final err = e.error;
  return err is ApiException && err.statusCode == statusCode;
}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    mockDio = _MockDio();
    repo = ExpenseRepository(mockDio);
  });

  group('fetchGroupExpenses', () {
    test(
      'calls GET /expenses/ with group_id, page, and limit query params',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/expenses/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: <String, dynamic>{
              'data': [
                expenseListItemJson('11111111-1111-1111-1111-111111111111'),
                expenseListItemJson('22222222-2222-2222-2222-222222222222'),
              ],
              'pagination': <String, dynamic>{
                'count': 2,
                'next': null,
                'previous': null,
              },
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/expenses/'),
          ),
        );

        final result = await repo.fetchGroupExpenses(_groupId);
        expect(result, hasLength(2));
        expect(result.first, isA<ExpenseListModel>());
        expect(result.first.id, '11111111-1111-1111-1111-111111111111');

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '/expenses/',
            queryParameters: <String, dynamic>{
              'group_id': _groupId,
              'page': 1,
              'limit': 20,
            },
          ),
        ).called(1);
      },
    );
  });

  group('fetchExpenseDetail', () {
    test('parses ExpenseDetailModel from response data wrapper', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/expenses/$_expenseId/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{'data': expenseDetailJson()},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/expenses/$_expenseId/'),
        ),
      );

      final result = await repo.fetchExpenseDetail(_expenseId);
      expect(result, isA<ExpenseDetailModel>());
      expect(result.id, _expenseId);
      expect(result.splits, hasLength(1));
    });

    test(
      'propagates DioException with nested ApiException on 403',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/expenses/$_expenseId/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/expenses/$_expenseId/'),
            response: Response<void>(
              statusCode: 403,
              requestOptions: RequestOptions(path: '/expenses/$_expenseId/'),
            ),
            type: DioExceptionType.badResponse,
            error: const ApiException(statusCode: 403, message: 'forbidden'),
          ),
        );

        await expectLater(
          repo.fetchExpenseDetail(_expenseId),
          throwsA(predicate((Object e) => _dioHasApiError(e, 403))),
        );
      },
    );
  });

  group('createExpense', () {
    test('sends POST /expenses/ and parses 201 detail payload', () async {
      final body = <String, dynamic>{
        'group_id': _groupId,
        'paid_by': _paidById,
        'amount': '10.00',
        'currency': 'BRL',
        'description': 'Test',
        'category': 'geral',
        'expense_date': '2024-02-01',
        'split_method': 'equal',
        'splits': <Map<String, dynamic>>[],
      };

      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/expenses/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{'data': expenseDetailJson()},
          statusCode: 201,
          requestOptions: RequestOptions(path: '/expenses/'),
        ),
      );

      final result = await repo.createExpense(body);
      expect(result, isA<ExpenseDetailModel>());
      expect(result.id, _expenseId);

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/expenses/',
          data: body,
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('deleteExpense', () {
    test('calls DELETE /expenses/{id}/ and completes on 204', () async {
      when(
        () => mockDio.delete<void>(
          '/expenses/$_expenseId/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/expenses/$_expenseId/'),
        ),
      );

      await repo.deleteExpense(_expenseId);

      verify(
        () => mockDio.delete<void>(
          '/expenses/$_expenseId/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });

  group('fetchReceiptUploadUrl', () {
    test('returns record with uploadUrl and fileKey from data wrapper', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/expenses/$_expenseId/receipt-upload-url/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'upload_url': 'https://s3.example/presigned',
              'file_key': 'receipts/x.png',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(
            path: '/expenses/$_expenseId/receipt-upload-url/',
          ),
        ),
      );

      final result = await repo.fetchReceiptUploadUrl(_expenseId);
      expect(result.uploadUrl, 'https://s3.example/presigned');
      expect(result.fileKey, 'receipts/x.png');

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/expenses/$_expenseId/receipt-upload-url/',
          queryParameters: <String, dynamic>{'content_type': 'image/jpeg'},
        ),
      ).called(1);
    });

    test('passes custom content type query param', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/expenses/$_expenseId/receipt-upload-url/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'upload_url': 'https://s3.example/p',
              'file_key': 'k',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/'),
        ),
      );

      await repo.fetchReceiptUploadUrl(_expenseId, contentType: 'image/png');

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/expenses/$_expenseId/receipt-upload-url/',
          queryParameters: <String, dynamic>{'content_type': 'image/png'},
        ),
      ).called(1);
    });
  });

  group('confirmReceiptUpload', () {
    test(
      'sends PATCH receipts/confirm with file_key and parses ExpenseDetailModel',
      () async {
        const fileKey = 'receipts/exp/r.png';
        when(
          () => mockDio.patch<Map<String, dynamic>>(
            '/expenses/$_expenseId/receipts/confirm/',
            data: any(named: 'data'),
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: <String, dynamic>{'data': expenseDetailJson()},
            statusCode: 200,
            requestOptions:
                RequestOptions(path: '/expenses/$_expenseId/receipts/confirm/'),
          ),
        );

        final result = await repo.confirmReceiptUpload(_expenseId, fileKey);
        expect(result, isA<ExpenseDetailModel>());
        expect(result.receiptUrls, isNotEmpty);

        verify(
          () => mockDio.patch<Map<String, dynamic>>(
            '/expenses/$_expenseId/receipts/confirm/',
            data: <String, dynamic>{'file_key': fileKey},
            queryParameters: any(named: 'queryParameters'),
          ),
        ).called(1);
      },
    );
  });

  group('deleteReceipt', () {
    test('sends DELETE receipts/ with file_key body on 204', () async {
      const fileKey = 'receipts/exp/r.png';
      when(
        () => mockDio.delete<void>(
          '/expenses/$_expenseId/receipts/',
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<void>(
          statusCode: 204,
          requestOptions: RequestOptions(path: '/expenses/$_expenseId/receipts/'),
        ),
      );

      await repo.deleteReceipt(_expenseId, fileKey);

      verify(
        () => mockDio.delete<void>(
          '/expenses/$_expenseId/receipts/',
          data: <String, dynamic>{'file_key': fileKey},
          queryParameters: any(named: 'queryParameters'),
        ),
      ).called(1);
    });
  });
}
