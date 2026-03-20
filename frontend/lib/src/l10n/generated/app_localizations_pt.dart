// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Rachae';

  @override
  String get loginTitle => 'Divida despesas sem atrito';

  @override
  String get loginSubtitle => 'Entre com Google para continuar.';

  @override
  String get signInWithGoogle => 'Continuar com Google';

  @override
  String get unsupportedPlatformMessage =>
      'O login com Google está disponível apenas para navegadores web e iOS nesta etapa.';

  @override
  String get oauthFailed => 'Não foi possível iniciar o login com Google.';

  @override
  String get homeTitle => 'Painel';

  @override
  String get signOut => 'Sair';

  @override
  String authenticatedMessage(Object email) {
    return 'Sessão iniciada como $email';
  }

  @override
  String get stageOneReady => 'A fundação da etapa 1 está pronta.';
}
