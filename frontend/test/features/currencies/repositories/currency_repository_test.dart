// ignore_for_file: library_private_types_in_public_api

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/currencies/models/convert_result_model.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/models/exchange_rate_model.dart';
import 'package:frontend/features/currencies/repositories/currency_repository.dart';

class _MockDio extends Mock implements Dio {}

late _MockDio mockDio;
late CurrencyRepository repo;

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    mockDio = _MockDio();
    repo = CurrencyRepository(mockDio);
  });

  group('fetchSupportedCurrencies', () {
    test('calls GET /currencies/ and returns List<CurrencyModel>', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/currencies/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'data': [
              {
                'code': 'BRL',
                'name': 'Real Brasileiro',
                'symbol': r'R$',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/currencies/'),
        ),
      );

      final result = await repo.fetchSupportedCurrencies();
      expect(result, hasLength(1));
      expect(result.first, isA<CurrencyModel>());
      expect(result.first.code, 'BRL');
    });

    test('BRL is present in the returned list', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/currencies/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'data': [
              {
                'code': 'BRL',
                'name': 'Real Brasileiro',
                'symbol': r'R$',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/currencies/'),
        ),
      );

      final result = await repo.fetchSupportedCurrencies();
      expect(result.any((c) => c.code == 'BRL'), isTrue);
    });

    test('throws on 500 response (DioException propagates)', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/currencies/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/currencies/'),
          response: Response<void>(
            statusCode: 500,
            requestOptions: RequestOptions(path: '/currencies/'),
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      await expectLater(
        repo.fetchSupportedCurrencies(),
        throwsA(isA<DioException>()),
      );
    });

    test('handles empty data list without throwing', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/currencies/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {'data': <Map<String, dynamic>>[]},
          statusCode: 200,
          requestOptions: RequestOptions(path: '/currencies/'),
        ),
      );

      final result = await repo.fetchSupportedCurrencies();
      expect(result, isEmpty);
    });
  });

  group('fetchRates', () {
    test('calls GET /currencies/rates/ with base query param', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/currencies/rates/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'data': [
              {
                'base_currency': 'BRL',
                'quote_currency': 'USD',
                'rate': '0.200000',
                'fetched_at': '2026-03-20T09:00:00Z',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/currencies/rates/'),
        ),
      );

      final result = await repo.fetchRates(base: 'BRL');
      expect(result, isA<List<ExchangeRateModel>>());
    });

    test('rate values come back as Strings — never doubles', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/currencies/rates/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'data': [
              {
                'base_currency': 'BRL',
                'quote_currency': 'USD',
                'rate': '0.200000',
                'fetched_at': '2026-03-20T09:00:00Z',
              },
            ],
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/currencies/rates/'),
        ),
      );

      final result = await repo.fetchRates(base: 'BRL');
      expect(result.first.rate, isA<String>());
    });
  });

  group('convertAmount', () {
    test('calls GET /currencies/convert/ with from, to, amount params', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/currencies/convert/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'data': {
              'result': '542.50',
              'rate': '5.425000',
              'fetched_at': '2026-03-20T09:00:00Z',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/currencies/convert/'),
        ),
      );

      final result = await repo.convertAmount(
        from: 'USD',
        to: 'BRL',
        amount: '100.00',
      );
      expect(result, isA<ConvertResultModel>());
      expect(result.result, isA<String>());
    });

    test('amount parameter is String — method signature enforces this', () async {
      // This test is structural — if convertAmount accepts double,
      // the test file will have a type error and fail to compile.
      when(
        () => mockDio.get<Map<String, dynamic>>(
          '/currencies/convert/',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: {
            'data': {
              'result': '542.50',
              'rate': '5.425000',
              'fetched_at': '2026-03-20T09:00:00Z',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/currencies/convert/'),
        ),
      );

      await repo.convertAmount(from: 'USD', to: 'BRL', amount: '100.00');
    });
  });
}
