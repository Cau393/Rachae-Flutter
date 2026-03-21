import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Maps a backend expense category slug to its localised display name.
/// Returns the raw slug as fallback for unknown values (future-proof).
String categoryDisplayName(AppLocalizations l10n, String slug) {
  return switch (slug) {
    'geral' => l10n.categoryGeral,
    'comida' => l10n.categoryComida,
    'transporte' => l10n.categoryTransporte,
    'moradia' => l10n.categoryMoradia,
    'lazer' => l10n.categoryLazer,
    'viagem' => l10n.categoryViagem,
    'utilidades' => l10n.categoryUtilidades,
    _ => slug,
  };
}
