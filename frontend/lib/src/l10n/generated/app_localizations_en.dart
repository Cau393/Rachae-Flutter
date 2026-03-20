// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Rachae';

  @override
  String get loginTitle => 'Split expenses without friction';

  @override
  String get loginSubtitle => 'Sign in with Google to continue.';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get unsupportedPlatformMessage =>
      'Google sign-in is only available on web browsers and iOS in this stage.';

  @override
  String get oauthFailed => 'Google sign-in could not be started.';

  @override
  String get homeTitle => 'Dashboard';

  @override
  String get signOut => 'Sign out';

  @override
  String authenticatedMessage(Object email) {
    return 'Signed in as $email';
  }

  @override
  String get stageOneReady => 'Stage 1 foundation is ready.';
}
