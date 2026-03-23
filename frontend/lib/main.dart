import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'src/app.dart';
import 'src/auth/oauth_callback_history_cleanup.dart';
import 'src/config/app_config.dart';

bool get _isIosNative =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

/// Dismisses [SFSafariViewController] opened by OAuth ([url_launcher] in-app
/// mode). Without this, the sheet can stay on an error page after the custom
/// scheme deep link returns to the app.
void _maybeDismissOAuthSafari(Uri? uri) {
  if (uri == null || !_isIosNative) return;
  if (uri.scheme != Uri.parse(AppConfig.iosRedirectUrl).scheme) return;
  unawaited(closeInAppWebView());
}

void _installIosOAuthSafariDismissOnDeepLink() {
  final appLinks = AppLinks();
  unawaited(
    appLinks.getInitialLink().then(_maybeDismissOAuthSafari, onError: (_, _) {}),
  );
  appLinks.uriLinkStream.listen(
    _maybeDismissOAuthSafari,
    onError: (_, _) {},
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  cleanupOAuthCallbackHistory();
  _installIosOAuthSafariDismissOnDeepLink();
  runApp(const ProviderScope(child: RachaeApp()));
}
