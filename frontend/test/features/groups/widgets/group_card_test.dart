import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/groups/models/group_summary_model.dart';
import 'package:frontend/features/groups/widgets/group_card.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  GroupSummaryModel model({
    String id = 'g1',
    String name = 'Viagem SP',
    String type = 'home',
    String currency = 'BRL',
    int memberCount = 3,
    String yourNetBalance = '10.00',
    DateTime? createdAt,
  }) {
    return GroupSummaryModel(
      id: id,
      name: name,
      type: type,
      currency: currency,
      memberCount: memberCount,
      yourNetBalance: yourNetBalance,
      createdAt: createdAt ?? DateTime.utc(2024, 1, 1),
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required GroupSummaryModel m,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: GroupCard(
            model: m,
            onTap: onTap ?? () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppLocalizations l10nFor(WidgetTester tester) {
    final ctx = tester.element(find.byType(GroupCard));
    return AppLocalizations.of(ctx)!;
  }

  group('GroupCard', () {
    testWidgets('non-zero balance: one CurrencyFormatterWidget with showSign and colorCoded',
        (tester) async {
      await pumpCard(tester, m: model(yourNetBalance: '42.50'));
      expect(find.byType(CurrencyFormatterWidget), findsOneWidget);
      final fmt = tester.widget<CurrencyFormatterWidget>(
        find.byType(CurrencyFormatterWidget),
      );
      expect(fmt.showSign, isTrue);
      expect(fmt.colorCoded, isTrue);
    });

    testWidgets('zero balance: no CurrencyFormatterWidget; shows localized groupBalanceZero',
        (tester) async {
      await pumpCard(tester, m: model(yourNetBalance: '0.00'));
      expect(find.byType(CurrencyFormatterWidget), findsNothing);
      expect(find.text(l10nFor(tester).groupBalanceZero), findsOneWidget);
    });

    for (final entry in <(String, IconData)>[
      ('home', Icons.home),
      ('trip', Icons.flight),
      ('couple', Icons.favorite),
      ('other', Icons.group),
    ]) {
      testWidgets('leading Icon for type ${entry.$1}', (tester) async {
        await pumpCard(tester, m: model(type: entry.$1));
        final iconFinder = find.descendant(
          of: find.byType(GroupCard),
          matching: find.byType(Icon),
        );
        final icon = tester.widget<Icon>(iconFinder);
        expect(icon.icon, entry.$2);
      });
    }

    testWidgets('tap invokes onTap', (tester) async {
      var n = 0;
      await pumpCard(
        tester,
        m: model(),
        onTap: () => n++,
      );
      await tester.tap(find.byType(ListTile));
      await tester.pumpAndSettle();
      expect(n, 1);
    });

    testWidgets('subtitle: member count l10n and currency code', (tester) async {
      await pumpCard(
        tester,
        m: model(memberCount: 4, currency: 'USD'),
      );
      final l10n = l10nFor(tester);
      expect(
        find.text('${l10n.groupMemberCount(4)} · USD'),
        findsOneWidget,
      );
    });
  });
}
