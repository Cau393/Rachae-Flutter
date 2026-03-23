/// MVP default ISO 4217 currency code for new users/groups and expense forms.
/// Centralized so `lib/features/` can import this instead of raw `'BRL'` literals
/// (see `test/l10n/l10n_no_hardcoded_test.dart`).
const String kDefaultCurrencyCode = 'BRL';
