import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/auth/widgets/auth_loading_overlay.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  /// Must match [AppLocalizations.loadingLabel] for `locale: pt_BR`.
  const expectedLoadingLabelPtBr = 'Carregando...';

  Widget overlayHarness({
    required bool overlayVisible,
    required VoidCallback onBackgroundTap,
  }) {
    return MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Stack(
          key: const Key('auth_overlay_test_stack'),
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onBackgroundTap,
                child: Container(color: Colors.white),
              ),
            ),
            Positioned.fill(
              child: AuthLoadingOverlay(isVisible: overlayVisible),
            ),
          ],
        ),
      ),
    );
  }

  group('AuthLoadingOverlay', () {
    testWidgets('isVisible true shows CircularProgressIndicator', (
      tester,
    ) async {
      await tester.pumpWidget(
        overlayHarness(overlayVisible: true, onBackgroundTap: () {}),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(AuthLoadingOverlay),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'isVisible true blocks taps to Stack content below (no pass-through)',
      (tester) async {
        var backgroundTaps = 0;
        await tester.pumpWidget(
          overlayHarness(
            overlayVisible: true,
            onBackgroundTap: () => backgroundTaps++,
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final stackCenter = tester.getCenter(
          find.byKey(const Key('auth_overlay_test_stack')),
        );
        await tester.tapAt(stackCenter);
        await tester.pump();

        expect(backgroundTaps, 0);
      },
    );

    testWidgets('isVisible true has Semantics with non-empty label (loading)', (
      tester,
    ) async {
      await tester.pumpWidget(
        overlayHarness(overlayVisible: true, onBackgroundTap: () {}),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.descendant(
          of: find.byType(AuthLoadingOverlay),
          matching: find.bySemanticsLabel(expectedLoadingLabelPtBr),
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'isVisible false leaves no overlay content (no progress / no loading semantics)',
      (tester) async {
        await tester.pumpWidget(
          overlayHarness(overlayVisible: false, onBackgroundTap: () {}),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(
          find.descendant(
            of: find.byType(AuthLoadingOverlay),
            matching: find.byType(CircularProgressIndicator),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(AuthLoadingOverlay),
            matching: find.bySemanticsLabel(expectedLoadingLabelPtBr),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'isVisible false: AuthLoadingOverlay type not mounted when parent omits it',
      (tester) async {
        var backgroundTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('pt', 'BR'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => backgroundTaps++,
                      child: Container(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AuthLoadingOverlay), findsNothing);
      },
    );
  });
}
