import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/profile/models/ads_status_model.dart';
import 'package:frontend/features/profile/providers/ads_repository_provider.dart';
import 'package:frontend/features/profile/providers/ads_status_provider.dart';
import 'package:frontend/features/profile/repositories/ads_repository.dart';

class _MockAdsRepository extends Mock implements AdsRepository {}

void main() {
  late _MockAdsRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockAdsRepository();
    container = ProviderContainer(
      overrides: [
        adsRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('AdsStatusProvider', () {
    test('returns AdsStatusModel when API succeeds', () async {
      when(() => mockRepo.fetchAdsStatus()).thenAnswer(
        (_) async => const AdsStatusModel(
          isAdFree: false,
          subscriptionStatus: null,
          planExpiresAt: null,
          planType: null,
        ),
      );

      final model = await container.read(adsStatusProvider.future);
      expect(model.isAdFree, isFalse);
    });

    test('isAdFree is false for new user', () async {
      when(() => mockRepo.fetchAdsStatus()).thenAnswer(
        (_) async => const AdsStatusModel(
          isAdFree: false,
        ),
      );

      final model = await container.read(adsStatusProvider.future);
      expect(model.isAdFree, isFalse);
    });

    test('isAdFree is true after subscription activated', () async {
      when(() => mockRepo.fetchAdsStatus()).thenAnswer(
        (_) async => const AdsStatusModel(
          isAdFree: true,
          subscriptionStatus: 'active',
          planExpiresAt: null,
          planType: 'monthly',
        ),
      );

      final model = await container.read(adsStatusProvider.future);
      expect(model.isAdFree, isTrue);
      expect(model.planType, 'monthly');
    });

    test('repository throw produces AsyncError', () async {
      when(() => mockRepo.fetchAdsStatus()).thenAnswer(
        (_) => Future<AdsStatusModel>.error(Exception('network')),
      );

      await expectLater(
        container.read(adsStatusProvider.future),
        throwsException,
      );
      expect(
        container.read(adsStatusProvider),
        isA<AsyncError<AdsStatusModel>>(),
      );
    });
  });
}
