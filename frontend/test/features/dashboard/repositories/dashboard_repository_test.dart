// ignore_for_file: library_private_types_in_public_api

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/repositories/dashboard_repository.dart';

class _MockDio extends Mock implements Dio {}

late _MockDio mockDio;
late DashboardRepository repo;

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    mockDio = _MockDio();
    repo = DashboardRepository(mockDio);
  });

  group('fetchBalanceSummary', () {
    test(
      'calls GET /users/me/ once with no query parameters and returns BalanceSummaryModel',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/users/me/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: {
              'total_owed': '45.00',
              'total_owing': '120.50',
              'net_balance': '-75.50',
              'currency': 'BRL',
              'email': 'x@x.com',
              'display_name': 'Test',
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/users/me/'),
          ),
        );

        final result = await repo.fetchBalanceSummary();

        expect(result, isA<BalanceSummaryModel>());
        expect(result.totalOwed, '45.00');
        expect(result.totalOwing, '120.50');
        expect(result.netBalance, '-75.50');
        expect(result.currency, 'BRL');

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '/users/me/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).called(1);
      },
    );

    test(
      'throws ApiException with statusCode 401 when Dio returns 401',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/users/me/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/users/me/'),
            response: Response<void>(
              statusCode: 401,
              requestOptions: RequestOptions(path: '/users/me/'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          repo.fetchBalanceSummary(),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      },
    );

    test(
      'throws ApiException with statusCode 500 when Dio returns 500',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/users/me/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/users/me/'),
            response: Response<void>(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/users/me/'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          repo.fetchBalanceSummary(),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
          ),
        );
      },
    );
  });

  group('fetchActivity', () {
    test(
      'calls GET /ledger/activity/ with page=1 and limit=20 and returns empty list',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/ledger/activity/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => Response<Map<String, dynamic>>(
            data: {
              'data': {'activities': <dynamic>[]},
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: '/ledger/activity/'),
          ),
        );

        final result = await repo.fetchActivity();

        expect(result, isEmpty);

        verify(
          () => mockDio.get<Map<String, dynamic>>(
            '/ledger/activity/',
            queryParameters: {'page': 1, 'limit': 20},
          ),
        ).called(1);
      },
    );

    test('sends page=2 when fetchActivity is called with page 2', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/ledger/activity/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'data': {'activities': <dynamic>[]},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/ledger/activity/'),
        ),
      );

      await repo.fetchActivity(page: 2);

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/ledger/activity/',
          queryParameters: {'page': 2, 'limit': 20},
        ),
      ).called(1);
    });

    test(
      'throws ApiException with statusCode 401 when Dio returns 401',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/ledger/activity/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/ledger/activity/'),
            response: Response<void>(
              statusCode: 401,
              requestOptions: RequestOptions(path: '/ledger/activity/'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          repo.fetchActivity(),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 401),
          ),
        );
      },
    );

    test(
      'throws ApiException with statusCode 500 when Dio returns 500',
      () async {
        when(
          () => mockDio.get<Map<String, dynamic>>(
            '/ledger/activity/',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(path: '/ledger/activity/'),
            response: Response<void>(
              statusCode: 500,
              requestOptions: RequestOptions(path: '/ledger/activity/'),
            ),
            type: DioExceptionType.badResponse,
          ),
        );

        await expectLater(
          repo.fetchActivity(),
          throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'statusCode', 500),
          ),
        );
      },
    );
  });

  group('fetchNextActivityPage', () {
    test('delegates to fetchActivity with the given page', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/ledger/activity/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'data': {'activities': <dynamic>[]},
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/ledger/activity/'),
        ),
      );

      await repo.fetchNextActivityPage(3);

      verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/ledger/activity/',
          queryParameters: {'page': 3, 'limit': 20},
        ),
      ).called(1);
    });
  });
}
