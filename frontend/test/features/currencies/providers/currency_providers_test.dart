// ignore_for_file: library_private_types_in_public_api

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:frontend/features/currencies/models/convert_result_model.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';
import 'package:frontend/features/currencies/models/exchange_rate_model.dart';
import 'package:frontend/features/currencies/providers/currency_providers.dart';
import 'package:frontend/features/currencies/repositories/currency_repository.dart';

class _MockCurrencyRepository extends Mock implements CurrencyRepository {}

void main() {
  late _MockCurrencyRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = _MockCurrencyRepository();
    container = ProviderContainer(
      overrides: [
        currencyRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('currencyListProvider', () {
    test('initial state is AsyncLoading', () {
      final completer = Completer<List<CurrencyModel>>();
      when(() => mockRepo.fetchSupportedCurrencies())
          .thenAnswer((_) => completer.future);

      final state = container.read(currencyListProvider);
      expect(state, isA<AsyncLoading>());
    });

    test('resolves to AsyncData with list after successful fetch', () async {
      when(() => mockRepo.fetchSupportedCurrencies()).thenAnswer(
        (_) async => [
          CurrencyModel(code: 'BRL', name: 'Real', symbol: r'R$'),
          CurrencyModel(code: 'USD', name: 'Dólar', symbol: r'$'),
        ],
      );

      await container.read(currencyListProvider.future);
      expect(container.read(currencyListProvider), isA<AsyncData>());
      expect(container.read(currencyListProvider).value!, hasLength(2));
    });

    test('resolves to AsyncError when repository throws', () async {
      when(() => mockRepo.fetchSupportedCurrencies()).thenAnswer(
        (_) => Future<List<CurrencyModel>>.error(Exception('network')),
      );

      await expectLater(
        container.read(currencyListProvider.future),
        throwsException,
      );
      expect(container.read(currencyListProvider), isA<AsyncError>());
    });

    test('does NOT call repository more than once (session caching)', () async {
      when(() => mockRepo.fetchSupportedCurrencies())
          .thenAnswer((_) async => []);

      await container.read(currencyListProvider.future);
      await container.read(currencyListProvider.future);

      verify(() => mockRepo.fetchSupportedCurrencies()).called(1);
    });
  });

  group('selectedCurrencyProvider', () {
    test('initial value is \'BRL\'', () {
      expect(container.read(selectedCurrencyProvider), equals('BRL'));
    });

    test('select() updates to a new currency code', () {
      container.read(selectedCurrencyProvider.notifier).select('USD');
      expect(container.read(selectedCurrencyProvider), equals('USD'));
    });

    test('reset() returns to \'BRL\'', () {
      container.read(selectedCurrencyProvider.notifier).select('EUR');
      container.read(selectedCurrencyProvider.notifier).reset();
      expect(container.read(selectedCurrencyProvider), equals('BRL'));
    });
  });

  group('exchangeRatesProvider', () {
    test('returns a Future<List<ExchangeRateModel>> for given base', () async {
      when(() => mockRepo.fetchRates(base: 'BRL'))
          .thenAnswer((_) async => []);

      final rates = await container.read(exchangeRatesProvider('BRL').future);
      expect(rates, isA<List<ExchangeRateModel>>());
    });
  });

  group('convertAmountProvider', () {
    test('returns ConvertResultModel for valid ConvertParams', () async {
      when(
        () => mockRepo.convertAmount(
          from: 'USD',
          to: 'BRL',
          amount: '100.00',
        ),
      ).thenAnswer(
        (_) async => ConvertResultModel(
          result: '542.50',
          rate: '5.425',
          fetchedAt: DateTime.now(),
        ),
      );

      final params = ConvertParams(from: 'USD', to: 'BRL', amount: '100.00');
      final converted = await container.read(convertAmountProvider(params).future);
      expect(converted.result, isA<String>());
    });
  });
}
