import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/l10n/category_l10n.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/widgets/category_badge.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  Widget app(Widget home) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );
  }

  testWidgets('comida slug shows Chip with categoryComida label', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context)!;
            return const CategoryBadge(slug: 'comida');
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Chip), findsOneWidget);
    expect(find.text(categoryDisplayName(l10n, 'comida')), findsOneWidget);
    expect(find.text(l10n.categoryComida), findsOneWidget);
  });
}
