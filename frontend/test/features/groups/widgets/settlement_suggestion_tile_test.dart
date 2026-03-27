import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/groups/models/settlement_suggestion_model.dart';
import 'package:frontend/features/groups/widgets/settlement_suggestion_tile.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  const gid = '11111111-1111-1111-1111-111111111111';
  const payerUid = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const receiverUid = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';

  SettlementSuggestionModel suggestion() {
    return SettlementSuggestionModel.fromJson(<String, dynamic>{
      'payer_id': payerUid,
      'payer_name': 'PayerUnique',
      'receiver_id': receiverUid,
      'receiver_name': 'ReceiverUnique',
      'amount': '30.00',
      'currency': 'BRL',
    });
  }

  group('SettlementSuggestionTile', () {
    testWidgets('title contains payer and receiver names from groupDetailOwes',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SettlementSuggestionTile(
                groupId: gid,
                suggestion: suggestion(),
                currentUserId: payerUid,
              ),
            ),
          ),
          GoRoute(
            path: '/settle',
            builder: (_, _) => const Scaffold(body: Text('settle_page')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('PayerUnique'), findsWidgets);
      expect(find.textContaining('ReceiverUnique'), findsWidgets);
    });

    testWidgets('Settle up navigates to /settle with query params', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SettlementSuggestionTile(
                groupId: gid,
                suggestion: suggestion(),
                currentUserId: payerUid,
              ),
            ),
          ),
          GoRoute(
            path: '/settle',
            builder: (_, _) => const Scaffold(body: Text('settle_page')),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettlementSuggestionTile)),
      )!;
      await tester.tap(find.text(l10n.groupDetailSettleUp));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, '/settle');
      expect(router.state.uri.queryParameters['group_id'], gid);
      expect(router.state.uri.queryParameters['receiver_id'], receiverUid);
      expect(router.state.uri.queryParameters['amount'], '30.00');
    });

    testWidgets('non-payer does not see Settle up button', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: SettlementSuggestionTile(
                groupId: gid,
                suggestion: suggestion(),
                currentUserId: receiverUid,
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SettlementSuggestionTile)),
      )!;
      expect(find.text(l10n.groupDetailSettleUp), findsNothing);
    });
  });
}
