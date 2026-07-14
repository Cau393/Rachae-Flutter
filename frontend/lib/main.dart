import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/features/auth/invite_deep_link_bootstrap.dart';
import 'src/app.dart';
import 'src/auth/oauth_callback_history_cleanup.dart';
import 'src/config/app_config.dart';
import 'src/config/load_env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Repo `.env` is only readable here when cwd is on the host (e.g. some
  // desktop runs). On iOS devices use `--dart-define-from-file=../.env` or
  // `--dart-define=API_BASE_URL=` — see [AppConfig].
  if (!kIsWeb) {
    await loadRepoDotenv();
  }
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  await readIosInviteTokenFromInitialAppLink();
  cleanupOAuthCallbackHistory();
  runApp(const ProviderScope(child: RachaeApp()));
}
