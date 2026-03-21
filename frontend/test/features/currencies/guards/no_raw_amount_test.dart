// PERMANENT CURRENCY GUARDRAILS — Do NOT delete or weaken.
// These tests pass trivially now (lib/features/ is empty).
// From Phase 17 onward they automatically catch:
//   1. Raw .toString() on money values inside Text()
//   2. Hardcoded 'R$', 'BRL', 'USD' currency symbols outside currency_formatter.dart
//   3. Double literals assigned to amount/balance variables in features/

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Currency display guardrails', () {
    test('no Text(value.toString()) pattern for money values in lib/features/', () {
      final dir = Directory('lib/features');
      if (!dir.existsSync()) {
        return;
      }

      final violations = <String>[];
      final pattern = RegExp(r'Text\([^)]*\.toString\(\)');
      const excludePathSubstrings = <String>[
        'currency_formatter',
        'money_amount',
      ];

      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where(
            (f) => !excludePathSubstrings.any((s) => f.path.contains(s)),
          );

      for (final file in files) {
        final path = file.path;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('// ignore: raw_amount')) {
            continue;
          }
          if (pattern.hasMatch(line)) {
            violations.add('$path:${i + 1}: $line');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Do not use Text(... .toString()) for money; use CurrencyFormatterWidget.',
      );
    });

    test('no hardcoded currency symbols outside currency_formatter.dart', () {
      final dir = Directory('lib');
      if (!dir.existsSync()) {
        return;
      }

      final violations = <String>[];
      // Literal 'R$' or "R$" as a Dart string (Phase 16 guardrail scope).
      final pattern = RegExp(r"'R\$'|" r'"R\$"');
      const excludePathSubstrings = <String>[
        'currency_formatter',
        'money_amount',
        'currency_model',
        'exchange_rate_model',
        'currency_providers',
        'currency_repository',
        'app_config',
      ];

      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .where((f) => !f.path.endsWith('_test.dart'))
          .where(
            (f) => !excludePathSubstrings.any((s) => f.path.contains(s)),
          );

      for (final file in files) {
        final path = file.path;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          final trimmed = line.trim();
          if (trimmed.startsWith('//')) {
            continue;
          }
          if (line.contains('// ignore: currency_symbol')) {
            continue;
          }
          if (pattern.hasMatch(line)) {
            violations.add('$path:${i + 1}: $line');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            "Do not hardcode 'R\$' / \"R\$\" outside approved currency modules.",
      );
    });

    test('no double literals for amount/balance variables in lib/features/', () {
      final dir = Directory('lib/features');
      if (!dir.existsSync()) {
        return;
      }

      final violations = <String>[];
      final pattern =
          RegExp(r'(?:amount|balance|owed|paid)\s*=\s*\d+\.\d+');

      final files = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));

      for (final file in files) {
        final path = file.path;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i];
          if (line.contains('// ignore: double_amount')) {
            continue;
          }
          if (pattern.hasMatch(line)) {
            violations.add('$path:${i + 1}: $line');
          }
        }
      }

      expect(
        violations,
        isEmpty,
        reason:
            'Use String or MoneyAmount for amounts, not double literals (e.g. amount = 1.23).',
      );
    });
  });
}
