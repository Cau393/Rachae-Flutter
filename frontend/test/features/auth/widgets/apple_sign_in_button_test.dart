import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/auth/widgets/apple_sign_in_button.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  /// Must match [AppLocalizations.signInWithApple] for `locale: pt_BR`.
  const expectedSignInWithApplePtBr = 'Continuar com Apple';

  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onPressed,
    bool isLoading = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: AppleSignInButton(
              onPressed: onPressed,
              isLoading: isLoading,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    if (isLoading) {
      await tester.pump(const Duration(milliseconds: 100));
    } else {
      await tester.pumpAndSettle();
    }
  }

  group('AppleSignInButton', () {
    testWidgets('tapping calls onPressed once when enabled', (tester) async {
      var calls = 0;
      await pumpButton(tester, onPressed: () => calls++);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('isLoading true disables tap (onPressed not invoked)', (
      tester,
    ) async {
      var calls = 0;
      await pumpButton(tester, onPressed: () => calls++, isLoading: true);

      await tester.tap(find.byType(AppleSignInButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(calls, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('onPressed null renders disabled button', (tester) async {
      await pumpButton(tester, onPressed: null);

      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byType(AppleSignInButton),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('has Semantics with signInWithApple label', (tester) async {
      await pumpButton(tester, onPressed: () {});

      expect(
        find.descendant(
          of: find.byType(AppleSignInButton),
          matching: find.bySemanticsLabel(expectedSignInWithApplePtBr),
        ),
        findsOneWidget,
      );
    });

    testWidgets('displayed label matches AppLocalizations.signInWithApple', (
      tester,
    ) async {
      await pumpButton(tester, onPressed: () {});

      final ctx = tester.element(find.byType(AppleSignInButton));
      final l10n = AppLocalizations.of(ctx)!;

      final textWidget = tester.widget<Text>(
        find.descendant(
          of: find.byType(AppleSignInButton),
          matching: find.byType(Text),
        ),
      );
      expect(textWidget.data, l10n.signInWithApple);
      expect(textWidget.data, expectedSignInWithApplePtBr);
    });

    testWidgets('backgroundColor resolves to near-black (Apple HIG)', (
      tester,
    ) async {
      await pumpButton(tester, onPressed: () {});

      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byType(AppleSignInButton),
          matching: find.byType(FilledButton),
        ),
      );
      final bg = button.style?.backgroundColor?.resolve(<WidgetState>{});
      expect(bg, isNotNull);
      // Near-black: luminance very low (black = 0.0).
      expect(bg!.computeLuminance(), lessThan(0.15));
    });
  });
}
