import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/currency/currency_formatter_widget.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/groups/models/group_balance_model.dart';
import 'package:frontend/features/groups/widgets/balance_list_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  GroupBalanceModel balance({
    String userId = 'u1',
    String displayName = 'Ada',
    String netBalance = '12.50',
  }) {
    return GroupBalanceModel.fromJson(<String, dynamic>{
      'user_id': userId,
      'display_name': displayName,
      'net_balance': netBalance,
    });
  }

  group('BalanceListTile', () {
    testWidgets('contains CurrencyFormatterWidget with showSign and colorCoded',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BalanceListTile(
              balance: balance(),
              currency: 'BRL',
              isCurrentUser: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CurrencyFormatterWidget), findsOneWidget);
      final fmt = tester.widget<CurrencyFormatterWidget>(
        find.byType(CurrencyFormatterWidget),
      );
      expect(fmt.showSign, isTrue);
      expect(fmt.colorCoded, isTrue);
    });
  });
}
