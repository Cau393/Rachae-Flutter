import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:frontend/core/revenuecat/revenuecat.dart';
import 'package:frontend/features/ads/ad_targeting_config.dart';
import 'package:frontend/features/auth/invite_deep_link_bootstrap.dart';
import 'src/app.dart';
import 'src/auth/oauth_callback_history_cleanup.dart';
import 'src/config/app_config.dart';
import 'src/config/load_env.dart';

Future<void> _initializeNativeMobileAds() async {
  if (kIsWeb) return;
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    final status = await AppTrackingTransparency.requestTrackingAuthorization();
    AdTargetingConfig.instance.useNonPersonalizedAds =
        status != TrackingStatus.authorized;
  } else {
    AdTargetingConfig.instance.useNonPersonalizedAds = false;
  }
  await MobileAds.instance.initialize();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Repo `.env` is only readable here when cwd is on the host (e.g. some
  // desktop runs). On iOS devices use `--dart-define-from-file=../.env` or
  // `--dart-define=REVENUECAT_IOS_API_KEY=` — see [AppConfig.revenueCatIosApiKey].
  if (!kIsWeb) {
    await loadRepoDotenv();
  }
  await revenueCatConfigure();
  await _initializeNativeMobileAds();
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );
  await readIosInviteTokenFromInitialAppLink();
  cleanupOAuthCallbackHistory();
  runApp(const ProviderScope(child: RachaeApp()));
}
