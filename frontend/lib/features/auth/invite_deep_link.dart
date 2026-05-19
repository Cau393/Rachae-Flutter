import 'package:frontend/src/config/app_config.dart';

/// Parses `invite_token` from an iOS custom-scheme invite URL:
/// `io.supabase.rachae://invite?invite_token=...`
String? parseInviteTokenFromIosCustomSchemeUri(Uri? uri) {
  if (uri == null) return null;
  final scheme = Uri.parse(AppConfig.iosRedirectUrl).scheme;
  if (uri.scheme != scheme) return null;
  final host = uri.host.toLowerCase();
  if (host != 'invite') return null;
  final token = uri.queryParameters['invite_token']?.trim();
  if (token == null || token.isEmpty) {
    return null;
  }
  return token;
}

/// Builds the custom-scheme URL opened from mobile web to launch the iOS app.
Uri buildIosFriendInviteAppUri(String inviteToken) {
  final base = Uri.parse(AppConfig.iosRedirectUrl);
  return Uri(
    scheme: base.scheme,
    host: 'invite',
    queryParameters: <String, String>{'invite_token': inviteToken},
  );
}
