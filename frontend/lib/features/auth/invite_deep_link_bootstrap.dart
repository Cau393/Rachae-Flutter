import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:frontend/features/auth/invite_deep_link.dart';
import 'package:frontend/features/auth/ios_oauth_safari_dismiss.dart';

/// Set in [readIosInviteTokenFromInitialAppLink] before [runApp] so [GoRouter]
/// can use `/login?invite_token=…` as [initialLocation] (avoids losing the token
/// to the unauthenticated `/` → `/login` redirect race).
String? pendingIosInviteTokenFromColdStart;

Future<void> readIosInviteTokenFromInitialAppLink() async {
  pendingIosInviteTokenFromColdStart = null;
  if (kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.iOS) return;
  try {
    final uri = await AppLinks().getInitialLink();
    await maybeDismissInAppWebViewForIosOAuth(uri);
    pendingIosInviteTokenFromColdStart = parseInviteTokenFromIosCustomSchemeUri(
      uri,
    );
  } catch (_) {
    pendingIosInviteTokenFromColdStart = null;
  }
}

/// Initial route for [GoRouter]. Uses [pendingIosInviteTokenFromColdStart] once.
String inviteAwareInitialLocation() {
  final t = pendingIosInviteTokenFromColdStart;
  if (t != null && t.isNotEmpty) {
    return '/login?invite_token=${Uri.encodeQueryComponent(t)}';
  }
  return '/';
}
