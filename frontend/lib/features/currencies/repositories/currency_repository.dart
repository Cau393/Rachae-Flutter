import 'package:dio/dio.dart';

import '../models/currency_model.dart';
import '../models/exchange_rate_model.dart';
import '../models/convert_result_model.dart';

class CurrencyRepository {
  const CurrencyRepository(this._dio);

  final Dio _dio;

  Future<List<CurrencyModel>> fetchSupportedCurrencies() async {
    final response = await _dio.get<Map<String, dynamic>>('/currencies/');
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return CurrencyModel.fromJsonList(data);
  }

  Future<List<ExchangeRateModel>> fetchRates({String base = 'BRL'}) async { // ignore: hardcoded — API default base currency
    final response = await _dio.get<Map<String, dynamic>>(
      '/currencies/rates/',
      queryParameters: {'base': base},
    );
    final data = response.data!['data'] as List<dynamic>? ?? [];
    return ExchangeRateModel.fromJsonList(data);
  }

  /// [amount] is a String — NEVER a double.
  /// The backend expects amounts as strings ('100.00', not 100.00).
  Future<ConvertResultModel> convertAmount({
    required String from,
    required String to,
    required String amount,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/currencies/convert/',
      queryParameters: {'from': from, 'to': to, 'amount': amount},
    );
    return ConvertResultModel.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }
}
