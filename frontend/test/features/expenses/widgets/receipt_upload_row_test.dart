import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/widgets/receipt_upload_row.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Minimal valid 1×1 PNG (transparent).
final _minimalPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGhzNcFzQAAAABJRU5ErkJggg==',
);

void main() {
  late Directory tempDir;
  late File fileA;
  late File fileB;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('receipt_upload_row_test_');
    fileA = File('${tempDir.path}/a.png');
    fileB = File('${tempDir.path}/b.png');
    await fileA.writeAsBytes(_minimalPngBytes);
    await fileB.writeAsBytes(_minimalPngBytes);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  Widget app(Widget home) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );
  }

  group('ReceiptUploadRow', () {
    testWidgets('empty queue shows add receipt control', (tester) async {
      await tester.pumpWidget(
        app(
          ReceiptUploadRow(
            receiptQueue: const [],
            onAddReceipt: () {},
            onRemoveReceipt: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final label = AppLocalizations.of(
        tester.element(find.byType(ReceiptUploadRow)),
      )!
          .addExpenseReceiptLabel;

      expect(find.text(label), findsOneWidget);
      expect(find.byIcon(Icons.add_a_photo), findsOneWidget);
    });

    testWidgets('two files show two images and two remove icons',
        (tester) async {
      await tester.pumpWidget(
        app(
          ReceiptUploadRow(
            receiptQueue: [fileA, fileB],
            onAddReceipt: () {},
            onRemoveReceipt: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsNWidgets(2));
      expect(find.byIcon(Icons.close), findsNWidgets(2));
    });

    testWidgets('tapping add calls onAddReceipt', (tester) async {
      var addCount = 0;
      await tester.pumpWidget(
        app(
          ReceiptUploadRow(
            receiptQueue: const [],
            onAddReceipt: () => addCount++,
            onRemoveReceipt: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final label = AppLocalizations.of(
        tester.element(find.byType(ReceiptUploadRow)),
      )!
          .addExpenseReceiptLabel;

      await tester.tap(find.text(label));
      await tester.pumpAndSettle();

      expect(addCount, 1);
    });

    testWidgets('tapping first remove calls onRemoveReceipt with first file',
        (tester) async {
      File? removed;
      await tester.pumpWidget(
        app(
          ReceiptUploadRow(
            receiptQueue: [fileA, fileB],
            onAddReceipt: () {},
            onRemoveReceipt: (f) => removed = f,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close).first);
      await tester.pumpAndSettle();

      expect(removed, isNotNull);
      expect(removed!.path, fileA.path);
    });
  });
}
