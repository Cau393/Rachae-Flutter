// ignore_for_file: library_private_types_in_public_api

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/profile/repositories/ads_repository.dart';

class _MockDio extends Mock implements Dio {}

void main() {
  late _MockDio mockDio;
  late AdsRepository repo;

  setUp(() {
    mockDio = _MockDio();
    repo = AdsRepository(mockDio);
  });

  group('AdsRepository', () {
    test('fetchAdsStatus returns AdsStatusModel with is_ad_free field',
        () async {
      when(() => mockDio.get<Map<String, dynamic>>('/ads/status/')).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'is_ad_free': false,
              'subscription_status': null,
              'plan_expires_at': null,
              'plan_type': null,
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/ads/status/'),
        ),
      );

      final model = await repo.fetchAdsStatus();

      expect(model.isAdFree, isFalse);
    });

    test('createCheckoutSession returns checkout_url string', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/ads/create-checkout-session/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'checkout_url': 'https://checkout.stripe.com/test',
            },
          },
          statusCode: 201,
          requestOptions:
              RequestOptions(path: '/ads/create-checkout-session/'),
        ),
      );

      final url =
          await repo.createCheckoutSession(plan: 'monthly');

      expect(url, 'https://checkout.stripe.com/test');
    });

    test('createCheckoutSession with plan=yearly hits correct endpoint body',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/ads/create-checkout-session/',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'checkout_url': 'https://checkout.stripe.com/y',
            },
          },
          statusCode: 201,
          requestOptions:
              RequestOptions(path: '/ads/create-checkout-session/'),
        ),
      );

      await repo.createCheckoutSession(plan: 'yearly');

      verify(
        () => mockDio.post<Map<String, dynamic>>(
          '/ads/create-checkout-session/',
          data: <String, dynamic>{'plan': 'yearly'},
        ),
      ).called(1);
    });

    test('createPortalSession returns portal_url string', () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          '/ads/create-portal-session/',
        ),
      ).thenAnswer(
        (_) async => Response<Map<String, dynamic>>(
          data: <String, dynamic>{
            'data': <String, dynamic>{
              'portal_url': 'https://billing.stripe.com/portal',
            },
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: '/ads/create-portal-session/'),
        ),
      );

      final url = await repo.createPortalSession();

      expect(url, 'https://billing.stripe.com/portal');
    });
  });
}
