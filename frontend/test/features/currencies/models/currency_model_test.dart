import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/currencies/models/currency_model.dart';

void main() {
  const sampleJson = {
    'code': 'BRL',
    'name': 'Real Brasileiro',
    'symbol': r'R$',
  };

  test('fromJson parses code, name, and symbol', () {
    final model = CurrencyModel.fromJson(sampleJson);
    expect(model.code, 'BRL');
    expect(model.name, 'Real Brasileiro');
    expect(model.symbol, r'R$');
  });

  test('fromJson falls back to code when symbol key is absent', () {
    final model = CurrencyModel.fromJson({
      'code': 'XYZ',
      'name': 'Test Currency',
    });
    expect(model.symbol, equals('XYZ'));
  });

  test('toJson round-trips correctly', () {
    final result = CurrencyModel.fromJson(sampleJson).toJson();
    expect(result, equals(sampleJson));
  });

  test('equality is code-based — same code = equal regardless of name', () {
    final a = CurrencyModel(code: 'BRL', name: 'A', symbol: r'R$');
    final b = CurrencyModel(code: 'BRL', name: 'B', symbol: r'R$');
    expect(a, equals(b));
  });

  test('different codes are not equal', () {
    final a = CurrencyModel(
      code: 'BRL',
      name: 'Real',
      symbol: r'R$',
    );
    final b = CurrencyModel(
      code: 'USD',
      name: 'Dollar',
      symbol: r'$',
    );
    expect(a, isNot(equals(b)));
  });

  test('CurrencyModel.brl() convenience constructor returns correct defaults', () {
    expect(CurrencyModel.brl().code, 'BRL');
    expect(CurrencyModel.brl().symbol, r'R$');
  });

  test('fromJsonList parses a list of 2 currency objects', () {
    final list = CurrencyModel.fromJsonList([
      sampleJson,
      {
        'code': 'USD',
        'name': 'Dollar',
        'symbol': r'$',
      },
    ]);
    expect(list, hasLength(2));
    expect(list.first.code, 'BRL');
  });
}
