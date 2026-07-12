import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/src/l10n/generated/app_localizations.dart';

void _expectAllKeysNonEmpty(AppLocalizations l10n) {
  expect(l10n.appTitle, isNotEmpty);
  expect(l10n.loginTitle, isNotEmpty);
  expect(l10n.loginSubtitle, isNotEmpty);
  expect(l10n.signInWithGoogle, isNotEmpty);
  expect(l10n.homeTitle, isNotEmpty);
  expect(l10n.signOut, isNotEmpty);
  expect(l10n.loadingLabel, isNotEmpty);
  expect(l10n.errorGeneric, isNotEmpty);
  expect(l10n.retryLabel, isNotEmpty);
  expect(l10n.unsupportedPlatformMessage, isNotEmpty);
  expect(l10n.oauthFailed, isNotEmpty);
  expect(l10n.stageOneReady, isNotEmpty);
  expect(l10n.dashboardTitle, isNotEmpty);
  expect(l10n.dashboardStubMessage, isNotEmpty);
}

void main() {
  testWidgets('pt_BR locale has all required keys', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            _expectAllKeysNonEmpty(l10n);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('en locale has all required keys', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            _expectAllKeysNonEmpty(l10n);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('authenticatedMessage interpolates email parameter', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final message = l10n.authenticatedMessage('test@email.com');
            expect(message, contains('test@email.com'));
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  testWidgets('profileIapNotConfiguredDetail interpolates the diagnostic',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context)!;
            final message = l10n.profileIapNotConfiguredDetail(
              'offerings=2 current=null storeProducts=0/2',
            );
            expect(
              message,
              contains('offerings=2 current=null storeProducts=0/2'),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  });

  test('pt_BR and en have identical key counts', () {
    final enCount = _arbMessageKeyCount(
      File('lib/l10n/app_en.arb'),
    );
    final ptCount = _arbMessageKeyCount(
      File('lib/l10n/app_pt.arb'),
    );
    expect(ptCount, enCount);
  });
}

int _arbMessageKeyCount(File file) {
  final map = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  var n = 0;
  for (final e in map.entries) {
    if (e.key.startsWith('@')) continue;
    if (e.value is String) n++;
  }
  return n;
}
