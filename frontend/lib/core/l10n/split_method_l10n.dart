import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Maps a backend split method string to its localised display name.
String splitMethodDisplayName(AppLocalizations l10n, String method) {
  return switch (method) {
    'equal' => l10n.addExpenseSplitMethodEqual,
    'exact' => l10n.addExpenseSplitMethodExact,
    'percentage' => l10n.addExpenseSplitMethodPercentage,
    'shares' => l10n.addExpenseSplitMethodShares,
    _ => method,
  };
}
