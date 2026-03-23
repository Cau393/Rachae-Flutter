// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;

/// OAuth callback URL: same host, port, and path as the address bar (e.g.
/// `http://192.168.0.12:61523/login`), not [Uri.base] (can mismatch and make
/// Supabase fall back to Site URL like `http://localhost:3000`).
///
/// Omits query and fragment so `redirect_to` stays stable; add the same
/// pattern to Supabase **Redirect URLs** (e.g. `http://192.168.*.*:61523/**`).
String webOAuthRedirectUri() {
  final loc = html.window.location;
  final path = loc.pathname ?? '/';
  final origin = loc.origin;
  if (path.isEmpty || path == '/') {
    return '$origin/';
  }
  return '$origin$path';
}
