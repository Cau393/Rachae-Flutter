import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:frontend/src/config/app_config.dart';

/// Closes [SFSafariViewController] used for OAuth when the custom-scheme
/// callback returns to the app.
Future<void> maybeDismissInAppWebViewForIosOAuth(Uri? uri) async {
  if (uri == null || kIsWeb) return;
  if (defaultTargetPlatform != TargetPlatform.iOS) return;
  if (uri.scheme != Uri.parse(AppConfig.iosRedirectUrl).scheme) return;
  await closeInAppWebView();
}
