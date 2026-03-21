import 'package:flutter/material.dart';
// ignore: unused_import
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';
import 'package:frontend/core/l10n/group_type_l10n.dart';

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
  testWidgets('home maps to createGroupTypeHome', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      groupTypeDisplayName(l10n, 'home'),
      equals(l10n.createGroupTypeHome),
    );
  });

  testWidgets('trip maps to createGroupTypeTrip', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      groupTypeDisplayName(l10n, 'trip'),
      equals(l10n.createGroupTypeTrip),
    );
  });

  testWidgets('couple maps to createGroupTypeCouple', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      groupTypeDisplayName(l10n, 'couple'),
      equals(l10n.createGroupTypeCouple),
    );
  });

  testWidgets('other maps to createGroupTypeOther', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(
      groupTypeDisplayName(l10n, 'other'),
      equals(l10n.createGroupTypeOther),
    );
  });

  testWidgets('unknown type apartment returns raw type', (tester) async {
    final l10n = await _loadPtBrL10n(tester);
    expect(groupTypeDisplayName(l10n, 'apartment'), equals('apartment'));
  });
}
