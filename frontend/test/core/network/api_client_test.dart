import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Headers;

import 'package:frontend/core/network/api_client.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockHttpClientAdapter extends Mock implements HttpClientAdapter {}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  group('ApiClient', () {
    const testBaseUrl = 'http://localhost:8000/api/v1/';

    test('base URL ends with /api/v1/', () {
      final mockSupabase = MockSupabaseClient();
      final client = ApiClient(supabaseClient: mockSupabase);

      expect(client.dio.options.baseUrl, endsWith('/api/v1/'));
    });

    test('adds Authorization Bearer header when token is present', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      final session = MockSession();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(session);
      when(() => session.isExpired).thenReturn(false);
      when(() => session.accessToken).thenReturn('test_token');

      final interceptor = SupabaseTokenInterceptor(mockSupabase);
      final options = RequestOptions(path: '/x', baseUrl: testBaseUrl);
      final handler = RequestInterceptorHandler();
      interceptor.onRequest(options, handler);
      await pumpEventQueue();

      expect(options.headers['Authorization'], 'Bearer test_token');
    });

    test('does NOT add Authorization header when session is null', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);

      final interceptor = SupabaseTokenInterceptor(mockSupabase);
      final options = RequestOptions(path: '/x', baseUrl: testBaseUrl);
      final handler = RequestInterceptorHandler();
      interceptor.onRequest(options, handler);
      await pumpEventQueue();

      expect(options.headers['Authorization'], isNull);
    });

    Future<void> expectBadResponseMapsToApiException({
      required int statusCode,
    }) async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);

      final client = ApiClient(supabaseClient: mockSupabase);
      final mockAdapter = MockHttpClientAdapter();
      when(
        () => mockAdapter.close(force: any(named: 'force')),
      ).thenReturn(null);
      when(
        () => mockAdapter.fetch(any(), any(), any()),
      ).thenAnswer((_) async => ResponseBody.fromString('{}', statusCode));
      client.dio.httpClientAdapter = mockAdapter;

      await expectLater(
        client.dio.get<dynamic>('/any'),
        throwsA(
          isA<DioException>().having(
            (e) => e.error,
            'error',
            isA<ApiException>().having(
              (a) => a.statusCode,
              'statusCode',
              statusCode,
            ),
          ),
        ),
      );
    }

    test('onError maps 401 to DioException wrapping ApiException', () async {
      await expectBadResponseMapsToApiException(statusCode: 401);
    });

    test('onError maps 404 to DioException wrapping ApiException', () async {
      await expectBadResponseMapsToApiException(statusCode: 404);
    });

    test('onError maps 500 to DioException wrapping ApiException', () async {
      await expectBadResponseMapsToApiException(statusCode: 500);
    });

    test('GET request returns parsed response body', () async {
      final mockSupabase = MockSupabaseClient();
      final mockAuth = MockGoTrueClient();
      when(() => mockSupabase.auth).thenReturn(mockAuth);
      when(() => mockAuth.currentSession).thenReturn(null);

      final client = ApiClient(supabaseClient: mockSupabase);
      final mockAdapter = MockHttpClientAdapter();
      when(
        () => mockAdapter.close(force: any(named: 'force')),
      ).thenReturn(null);
      when(() => mockAdapter.fetch(any(), any(), any())).thenAnswer(
        (_) async => ResponseBody.fromString(
          '{"data":{"status":"ok"}}',
          200,
          headers: {
            Headers.contentTypeHeader: ['application/json'],
          },
        ),
      );

      client.dio.httpClientAdapter = mockAdapter;

      final response = await client.dio.get<dynamic>('/any');
      final data = response.data as Map<String, dynamic>;
      expect(data['data']['status'], 'ok');
    });
  });
}
