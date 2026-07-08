import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import 'package:frontend/features/profile/widgets/legal_links_section.dart';
import 'package:frontend/src/config/legal_config.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class _FakeUrlLauncher extends UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  bool canLaunchResult = true;

  @override
  Future<bool> canLaunch(String url) async => canLaunchResult;

  @override
  Future<bool> launch(
    String url, {
    required bool useSafariVC,
    required bool useWebView,
    required bool enableJavaScript,
    required bool enableDomStorage,
    required bool universalLinksOnly,
    required Map<String, String> headers,
    String? webOnlyWindowName,
  }) async {
    launchedUrls.add(url);
    return true;
  }

  @override
  LinkDelegate? get linkDelegate => null;
}

void main() {
  late _FakeUrlLauncher fakeLauncher;

  setUp(() {
    fakeLauncher = _FakeUrlLauncher();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  Future<void> pumpSection(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: LegalLinksSection()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows Terms of Use (EULA) and Privacy Policy links',
      (tester) async {
    await pumpSection(tester);

    expect(find.text('Terms of Use (EULA)'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
  });

  testWidgets('tapping Terms of Use opens the Apple EULA URL',
      (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Terms of Use (EULA)'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.launchedUrls, contains(LegalConfig.eulaUrl));
  });

  testWidgets('tapping Privacy Policy opens the privacy policy URL',
      (tester) async {
    await pumpSection(tester);

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.launchedUrls, contains(LegalConfig.privacyPolicyUrl));
  });

  testWidgets('shows a snackbar when the URL cannot be launched',
      (tester) async {
    fakeLauncher.canLaunchResult = false;
    await pumpSection(tester);

    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();

    expect(fakeLauncher.launchedUrls, isEmpty);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
