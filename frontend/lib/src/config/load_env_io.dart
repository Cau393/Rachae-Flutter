import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads repo-root `.env` only when those files exist in **this process** cwd
/// (typically desktop or some CLI tests). On **iOS/Android devices**, cwd is not
/// the repo on your machine — use `--dart-define-from-file` / `--dart-define`
/// for keys like `REVENUECAT_IOS_API_KEY`; see [AppConfig.revenueCatIosApiKey].
Future<void> loadRepoDotenv() async {
  final cwd = Directory.current.path;
  final candidates = [
    File('$cwd/../.env'),
    File('$cwd/.env'),
  ];
  for (final f in candidates) {
    try {
      if (f.existsSync()) {
        final s = await f.readAsString();
        if (s.trim().isNotEmpty) {
          dotenv.loadFromString(envString: s);
          return;
        }
      }
    } catch (_) {
      // fall through
    }
  }
  dotenv.loadFromString(envString: '', isOptional: true);
}
