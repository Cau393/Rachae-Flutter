// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/dashboard/models/balance_summary_model.dart';
import 'package:frontend/features/dashboard/providers/balance_summary_provider.dart';
import 'package:frontend/features/dashboard/repositories/dashboard_repository.dart';

class _MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late _MockDashboardRepository mockRepo;
  late ProviderContainer container;

  const fixedModel = BalanceSummaryModel(
    totalOwed: '45.00',
    totalOwing: '120.50',
    netBalance: '-75.50',
    currency: 'BRL',
  );

  setUp(() {
    mockRepo = _MockDashboardRepository();
    container = ProviderContainer(
      overrides: [dashboardRepositoryProvider.overrideWithValue(mockRepo)],
    );
  });

  tearDown(() => container.dispose());

  test('initial state is AsyncLoading while fetch is pending', () {
    final completer = Completer<BalanceSummaryModel>();
    when(
      () => mockRepo.fetchBalanceSummary(),
    ).thenAnswer((_) => completer.future);

    final state = container.read(balanceSummaryProvider);
    expect(state, isA<AsyncLoading<BalanceSummaryModel>>());
  });

  test(
    'await balanceSummaryProvider.future resolves to BalanceSummaryModel',
    () async {
      when(
        () => mockRepo.fetchBalanceSummary(),
      ).thenAnswer((_) async => fixedModel);

      final model = await container.read(balanceSummaryProvider.future);
      expect(model, fixedModel);
      expect(
        container.read(balanceSummaryProvider),
        isA<AsyncData<BalanceSummaryModel>>(),
      );
      expect(container.read(balanceSummaryProvider).value, fixedModel);
    },
  );

  test('invalidate triggers a second fetchBalanceSummary call', () async {
    when(
      () => mockRepo.fetchBalanceSummary(),
    ).thenAnswer((_) async => fixedModel);

    await container.read(balanceSummaryProvider.future);
    container.invalidate(balanceSummaryProvider);
    await container.read(balanceSummaryProvider.future);

    verify(() => mockRepo.fetchBalanceSummary()).called(2);
  });

  test('repository throw produces AsyncError', () async {
    when(() => mockRepo.fetchBalanceSummary()).thenAnswer(
      (_) => Future<BalanceSummaryModel>.error(Exception('network')),
    );

    await expectLater(
      container.read(balanceSummaryProvider.future),
      throwsException,
    );
    expect(
      container.read(balanceSummaryProvider),
      isA<AsyncError<BalanceSummaryModel>>(),
    );
  });

  test(
    'does not call repository more than once without invalidation',
    () async {
      when(
        () => mockRepo.fetchBalanceSummary(),
      ).thenAnswer((_) async => fixedModel);

      await container.read(balanceSummaryProvider.future);
      await container.read(balanceSummaryProvider.future);

      verify(() => mockRepo.fetchBalanceSummary()).called(1);
    },
  );
}
