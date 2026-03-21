import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Maps a backend group type string to its localised display name.
String groupTypeDisplayName(AppLocalizations l10n, String type) {
  return switch (type) {
    'home' => l10n.createGroupTypeHome,
    'trip' => l10n.createGroupTypeTrip,
    'couple' => l10n.createGroupTypeCouple,
    'other' => l10n.createGroupTypeOther,
    _ => type,
  };
}
