import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';
import 'package:frontend/core/l10n/role_l10n.dart';

Future<AppLocalizations> _loadPtBrL10n(WidgetTester tester) async {
  late AppLocalizations result;
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (ctx) {
          result = AppLocalizations.of(ctx)!;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return result;
}

void main() {
  testWidgets('ADMIN maps to groupDetailRoleAdmin', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      roleDisplayName(l10n, 'ADMIN'),
      equals(l10n.groupDetailRoleAdmin),
    );
  });

  testWidgets('MEMBER maps to groupDetailRoleMember', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      roleDisplayName(l10n, 'MEMBER'),
      equals(l10n.groupDetailRoleMember),
    );
  });

  testWidgets('VIEWER maps to groupDetailRoleViewer', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      roleDisplayName(l10n, 'VIEWER'),
      equals(l10n.groupDetailRoleViewer),
    );
  });

  testWidgets('unknown role OWNER returns raw role', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(roleDisplayName(l10n, 'OWNER'), equals('OWNER'));
  });
}
