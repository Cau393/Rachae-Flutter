import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/currencies/models/convert_result_model.dart';
import 'package:frontend/features/currencies/models/exchange_rate_model.dart';

void main() {
  const rateJson = {
    'base_currency': 'BRL',
    'quote_currency': 'USD',
    'rate': '0.200000',
    'fetched_at': '2026-03-20T09:00:00Z',
  };

  const convertJson = {
    'result': '542.50',
    'rate': '5.425000',
    'fetched_at': '2026-03-20T09:00:00Z',
  };

  group('ExchangeRateModel', () {
    test('fromJson parses baseCurrency, quoteCurrency, rate, fetchedAt', () {
      final model = ExchangeRateModel.fromJson(rateJson);
      expect(model.baseCurrency, 'BRL');
      expect(model.quoteCurrency, 'USD');
      expect(model.rate, '0.200000');
      expect(model.fetchedAt, isA<DateTime>());
    });

    test('rate field is a String — NEVER a double', () {
      // If this fails, the implementation has a type error — rate must NEVER be double
      expect(ExchangeRateModel.fromJson(rateJson).rate, isA<String>());
    });

    test('fromJsonList parses a list of 2 rate objects', () {
      final list = ExchangeRateModel.fromJsonList([rateJson, rateJson]);
      expect(list, hasLength(2));
    });
  });

  group('ConvertResultModel', () {
    test('fromJson parses result, rate, fetchedAt', () {
      final model = ConvertResultModel.fromJson(convertJson);
      expect(model.result, '542.50');
      expect(model.rate, '5.425000');
      expect(model.fetchedAt, isA<DateTime>());
    });

    test('result field is a String — NEVER a double', () {
      expect(ConvertResultModel.fromJson(convertJson).result, isA<String>());
    });

    test('toMoneyAmount creates a MoneyAmount with the correct values', () {
      final model = ConvertResultModel.fromJson(convertJson);
      final money = model.toMoneyAmount('BRL');
      expect(money.raw, '542.50');
      expect(money.currencyCode, 'BRL');
    });
  });
}
