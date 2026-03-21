import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/auth/widgets/auth_loading_overlay.dart';
import 'package:frontend/features/auth/widgets/rachae_logo.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class ThrowingGoogleAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();

  @override
  Future<void> signInWithGoogle() async {
    throw Exception('oauth');
  }
}

/// Holds [signInWithGoogle] until [hang] completes — for overlay-in-flight tests.
class HangingGoogleAuthNotifier extends AuthNotifier {
  HangingGoogleAuthNotifier(this._hang);
  final Completer<void> _hang;

  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();

  @override
  Future<void> signInWithGoogle() async {
    await _hang.future;
  }
}

/// [CircularProgressIndicator] in overlay animates forever — avoid [pumpAndSettle].
Future<void> pumpLogin(WidgetTester tester, AuthState authState) async {
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authNotifierProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LoginScreen(),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

AppLocalizations l10nFrom(WidgetTester tester) {
  final ctx = tester.element(find.byType(LoginScreen));
  return AppLocalizations.of(ctx)!;
}

/// Set before [pumpLogin]; must be cleared before the test ends (Flutter checks
/// [debugAssertAllFoundationVarsUnset] before [tearDown] runs).
void clearTestPlatform() {
  debugDefaultTargetPlatformOverride = null;
}

void main() {
  group('LoginScreen idle rendering', () {
    testWidgets(
      'Android: logo, loginTitle, loginSubtitle, unsupported — no Apple',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        await pumpLogin(tester, const AuthState.unauthenticated());
        clearTestPlatform();
        final l10n = l10nFrom(tester);

        expect(find.byType(RachaeLogo), findsOneWidget);
        expect(find.text(l10n.loginTitle), findsOneWidget);
        expect(find.text(l10n.loginSubtitle), findsOneWidget);
        expect(find.text(l10n.unsupportedPlatformMessage), findsOneWidget);
        expect(find.text(l10n.signInWithGoogle), findsNothing);
        expect(find.text(l10n.signInWithApple), findsNothing);
      },
    );

    testWidgets('iOS: logo, titles, Google and Apple sign-in', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await pumpLogin(tester, const AuthState.unauthenticated());
      clearTestPlatform();
      final l10n = l10nFrom(tester);

      expect(find.byType(RachaeLogo), findsOneWidget);
      expect(find.text(l10n.loginTitle), findsOneWidget);
      expect(find.text(l10n.loginSubtitle), findsOneWidget);
      expect(find.text(l10n.signInWithGoogle), findsOneWidget);
      expect(find.text(l10n.signInWithApple), findsOneWidget);
    });
  });

  group('LoginScreen loading state', () {
    testWidgets(
      'AuthLoadingOverlay visible while signInWithGoogle is in flight',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final hang = Completer<void>();
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(
              () => HangingGoogleAuthNotifier(hang),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authNotifierProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              locale: const Locale('pt', 'BR'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final l10n = l10nFrom(tester);
        await tester.tap(find.text(l10n.signInWithGoogle));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final overlay = tester.widget<AuthLoadingOverlay>(
          find.byType(AuthLoadingOverlay),
        );
        expect(overlay.isVisible, isTrue);
        expect(find.bySemanticsLabel(l10n.loadingLabel), findsOneWidget);
        expect(find.byType(RachaeLogo), findsOneWidget);
        expect(find.text(l10n.loginTitle), findsOneWidget);

        hang.complete();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final overlayAfter = tester.widget<AuthLoadingOverlay>(
          find.byType(AuthLoadingOverlay),
        );
        expect(overlayAfter.isVisible, isFalse);
        clearTestPlatform();
      },
    );
  });

  group('LoginScreen OAuth error', () {
    testWidgets(
      'signInWithGoogle throws — SnackBar with oauthFailed; no navigation',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(ThrowingGoogleAuthNotifier.new),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authNotifierProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              locale: const Locale('pt', 'BR'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const LoginScreen(),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final l10n = l10nFrom(tester);
        await tester.tap(find.bySemanticsLabel(l10n.signInWithGoogle));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump();

        expect(find.text(l10n.oauthFailed), findsOneWidget);
        expect(find.text(l10n.signInWithGoogle), findsOneWidget);
        clearTestPlatform();
      },
    );
  });

  group('LoginScreen platform guard', () {
    testWidgets(
      'non-web non-iOS shows unsupportedPlatformMessage not Google button',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.linux;
        await pumpLogin(tester, const AuthState.unauthenticated());
        clearTestPlatform();
        final l10n = l10nFrom(tester);

        expect(find.text(l10n.unsupportedPlatformMessage), findsOneWidget);
        expect(find.text(l10n.signInWithGoogle), findsNothing);
      },
    );
  });

  group('LoginScreen no hardcoded user strings', () {
    testWidgets('Text under LoginScreen matches l10n allowlist only', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      await pumpLogin(tester, const AuthState.unauthenticated());
      clearTestPlatform();
      final l10n = l10nFrom(tester);

      final allowed = <String>{
        l10n.loginTitle,
        l10n.loginSubtitle,
        l10n.signInWithGoogle,
        l10n.signInWithApple,
        l10n.unsupportedPlatformMessage,
      };

      final textNodes = find.descendant(
        of: find.byType(LoginScreen),
        matching: find.byType(Text),
      );
      expect(textNodes, findsWidgets);

      for (final e in textNodes.evaluate()) {
        final t = e.widget as Text;
        final data = t.data;
        if (data == null) continue;
        expect(
          allowed.contains(data),
          isTrue,
          reason: 'Unexpected Text data: $data',
        );
      }

      expect(find.text('Entrar'), findsNothing);
    });
  });

  group('LoginScreen no ads', () {
    testWidgets('no AdBanner or BannerAd in tree', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      await pumpLogin(tester, const AuthState.unauthenticated());
      clearTestPlatform();
      expect(
        find.byWidgetPredicate((w) {
          final name = '${w.runtimeType}';
          return name == 'AdBanner' || name == 'BannerAd';
        }),
        findsNothing,
      );
    });
  });

  group('LoginScreen accessibility', () {
    testWidgets(
      'Google and Apple buttons expose l10n labels to semantics tree',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        await pumpLogin(tester, const AuthState.unauthenticated());
        clearTestPlatform();
        final l10n = l10nFrom(tester);

        expect(find.bySemanticsLabel(l10n.signInWithGoogle), findsOneWidget);
        expect(find.bySemanticsLabel(l10n.signInWithApple), findsOneWidget);
      },
    );

  });
}
