import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Maps a backend GroupRole string to its localised display name.
String roleDisplayName(AppLocalizations l10n, String role) {
  return switch (role) {
    'ADMIN' => l10n.groupDetailRoleAdmin,
    'MEMBER' => l10n.groupDetailRoleMember,
    'VIEWER' => l10n.groupDetailRoleViewer,
    _ => role,
  };
}
