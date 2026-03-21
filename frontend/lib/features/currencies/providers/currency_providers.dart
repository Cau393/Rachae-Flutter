import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/core_providers.dart';
import '../models/convert_result_model.dart';
import '../models/currency_model.dart';
import '../models/exchange_rate_model.dart';
import '../repositories/currency_repository.dart';

// ---------------------------------------------------------------------------
// ConvertParams — parameter object for convertAmountProvider
// ---------------------------------------------------------------------------

class ConvertParams {
  const ConvertParams({
    required this.from,
    required this.to,
    required this.amount, // String — NEVER double
  });
  final String from;
  final String to;
  final String amount;

  @override
  bool operator ==(Object other) =>
      other is ConvertParams &&
      other.from == from &&
      other.to == to &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(from, to, amount);
}

// ---------------------------------------------------------------------------
// Repository provider
// ---------------------------------------------------------------------------

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  return CurrencyRepository(ref.watch(dioProvider));
});

// ---------------------------------------------------------------------------
// Currency list — fetched once per session (FutureProvider = auto-cached)
// ---------------------------------------------------------------------------

final currencyListProvider = FutureProvider<List<CurrencyModel>>(
  (ref) async {
    return await ref.watch(currencyRepositoryProvider).fetchSupportedCurrencies();
  },
  retry: (int retryCount, Object error) => null,
);

// ---------------------------------------------------------------------------
// Selected currency — for the AddExpenseScreen currency picker
// ---------------------------------------------------------------------------

final selectedCurrencyProvider =
    NotifierProvider<SelectedCurrencyNotifier, String>(
  SelectedCurrencyNotifier.new,
);

class SelectedCurrencyNotifier extends Notifier<String> {
  @override
  String build() => 'BRL'; // ignore: hardcoded — ISO 4217 default (MVP locale)

  void select(String code) => state = code;
  void reset() => state = 'BRL'; // ignore: hardcoded — ISO 4217 default (MVP locale)
}

// ---------------------------------------------------------------------------
// Exchange rates — parameterised by base currency
// ---------------------------------------------------------------------------

final exchangeRatesProvider =
    FutureProvider.family<List<ExchangeRateModel>, String>(
  (ref, base) async {
    return await ref.watch(currencyRepositoryProvider).fetchRates(base: base);
  },
  retry: (int retryCount, Object error) => null,
);

// ---------------------------------------------------------------------------
// Convert amount — parameterised by ConvertParams
// ---------------------------------------------------------------------------

final convertAmountProvider =
    FutureProvider.family<ConvertResultModel, ConvertParams>(
  (ref, params) async {
    return await ref.watch(currencyRepositoryProvider).convertAmount(
          from: params.from,
          to: params.to,
          amount: params.amount,
        );
  },
  retry: (int retryCount, Object error) => null,
);
