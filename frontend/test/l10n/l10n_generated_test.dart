import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

Widget _app(Locale locale, Widget home) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );
}

void main() {
  group('AppLocalizations pt_BR', () {
    testWidgets('appTitle resolves to Rachae', (tester) async {
      await tester.pumpWidget(
        _app(
          const Locale('pt', 'BR'),
          Builder(
            builder: (ctx) => Text(AppLocalizations.of(ctx)!.appTitle),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rachae'), findsOneWidget);
    });

    testWidgets('categoryGeral resolves to Geral', (tester) async {
      await tester.pumpWidget(
        _app(
          const Locale('pt', 'BR'),
          Builder(
            builder: (ctx) => Text(AppLocalizations.of(ctx)!.categoryGeral),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Geral'), findsOneWidget);
    });

    testWidgets('groupDetailOwes interpolates 3 placeholders correctly',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const Locale('pt', 'BR'),
          Builder(
            builder: (ctx) => Text(
              AppLocalizations.of(ctx)!.groupDetailOwes(
                'Ana',
                r'R$50,00',
                'Bob',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana deve R\$50,00 para Bob'), findsOneWidget);
    });

    testWidgets('addExpenseConvertedPreview interpolates amount and currency',
        (tester) async {
      await tester.pumpWidget(
        _app(
          const Locale('pt', 'BR'),
          Builder(
            builder: (ctx) => Text(
              AppLocalizations.of(ctx)!.addExpenseConvertedPreview(
                '50.00',
                'BRL',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('50.00'), findsOneWidget);
    });

    testWidgets('activityPaidBy interpolates name', (tester) async {
      await tester.pumpWidget(
        _app(
          const Locale('pt', 'BR'),
          Builder(
            builder: (ctx) => Text(
              AppLocalizations.of(ctx)!.activityPaidBy('Maria'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pago por Maria'), findsOneWidget);
    });
  });

  group('AppLocalizations en', () {
    testWidgets('appTitle resolves to Rachae in en', (tester) async {
      await tester.pumpWidget(
        _app(
          const Locale('en'),
          Builder(
            builder: (ctx) => Text(AppLocalizations.of(ctx)!.appTitle),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rachae'), findsOneWidget);
    });

    testWidgets('categoryGeral resolves to General in en', (tester) async {
      await tester.pumpWidget(
        _app(
          const Locale('en'),
          Builder(
            builder: (ctx) => Text(AppLocalizations.of(ctx)!.categoryGeral),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('General'), findsOneWidget);
    });

    testWidgets('groupDetailOwes interpolates in en', (tester) async {
      await tester.pumpWidget(
        _app(
          const Locale('en'),
          Builder(
            builder: (ctx) => Text(
              AppLocalizations.of(ctx)!.groupDetailOwes(
                'Ana',
                r'$50.00',
                'Bob',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ana owes \$50.00 to Bob'), findsOneWidget);
    });
  });

  group('Supported locales', () {
    test('supported locales contain pt and en', () {
      final locales = AppLocalizations.supportedLocales;
      expect(
        locales.any((l) => l.languageCode == 'pt'),
        isTrue,
      );
      expect(
        locales.any((l) => l.languageCode == 'en'),
        isTrue,
      );
    });
  });
}
