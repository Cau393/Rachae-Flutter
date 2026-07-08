import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/router/app_router.dart';
import '../core/theme/app_theme.dart';
import '../features/ads/ads_bootstrap.dart';
import '../features/auth/ios_app_link_listener.dart';
import 'l10n/generated/app_localizations.dart';

class RachaeApp extends ConsumerStatefulWidget {
  const RachaeApp({super.key});

  @override
  ConsumerState<RachaeApp> createState() => _RachaeAppState();
}

class _RachaeAppState extends ConsumerState<RachaeApp>
    with WidgetsBindingObserver {
  bool _adsInitStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // ATT (iOS) + AdMob init must happen after the first frame renders and
    // the app is actually `resumed` — requesting it during pre-`runApp`
    // startup is unreliable and can silently skip the system prompt. See
    // `docs/app-review-rejection-plan-2026-07-07.md` Issue 4.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeInitAds());
  }

  void _maybeInitAds() {
    if (_adsInitStarted) return;
    final state = WidgetsBinding.instance.lifecycleState;
    // On some platforms/tests lifecycleState is null right after the first
    // frame; treat that as resumed rather than waiting forever.
    if (state != null && state != AppLifecycleState.resumed) return;
    _adsInitStarted = true;
    initializeNativeMobileAds();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _maybeInitAds();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    return IosAppLinkListener(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
        routerConfig: router,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
      ),
    );
  }
}
