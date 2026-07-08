import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Loads repo-root `.env` when those files exist in **this process** cwd
/// (typically desktop or some CLI tests). On **iOS/Android devices**, cwd is
/// not the repo on your machine, so we fall back to the bundled
/// `assets/config/public.env` asset (public values only — API_BASE_URL and
/// publishable keys). Dart-defines (`--dart-define-from-file`) always take
/// precedence over dotenv values at the call sites, so this fallback only
/// matters for launches without defines (e.g. running from Xcode for StoreKit
/// Configuration testing).
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
  try {
    final bundled = await rootBundle.loadString('assets/config/public.env');
    if (bundled.trim().isNotEmpty) {
      dotenv.loadFromString(envString: bundled);
      return;
    }
  } catch (_) {
    // asset missing; fall through
  }
  dotenv.loadFromString(envString: '', isOptional: true);
}
