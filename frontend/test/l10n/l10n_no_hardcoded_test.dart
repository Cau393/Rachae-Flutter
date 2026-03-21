import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('no hardcoded Portuguese strings in lib/features/', () {
    // Scan all .dart files under lib/features/ for Text('...') with
    // Portuguese characters or common PT words not wrapped in l10n
    final featuresDir = Directory('lib/features');
    if (!featuresDir.existsSync()) return; // features/ built in Phase 17+

    final dartFiles = featuresDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    // Pattern: Text(' or Text(" followed by a non-empty string literal
    // that is NOT a key reference (i.e. not context.l10n.*)
    // This is a best-effort grep — more precise checks happen in PR review.
    final hardcodedPattern = RegExp(
      r'''Text\(\s*['"][A-Za-zÀ-ú]{3,}''',
    );

    final violations = <String>[];
    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (hardcodedPattern.hasMatch(lines[i]) &&
            !lines[i].contains('l10n.') &&
            !lines[i].contains('// ignore: hardcoded')) {
          violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(violations, isEmpty,
        reason: 'Hardcoded strings found:\n${violations.join('\n')}');
  });

  test('no hardcoded currency symbols in lib/features/', () {
    final featuresDir = Directory('lib/features');
    if (!featuresDir.existsSync()) return;

    final dartFiles = featuresDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    final currencyPattern = RegExp(r'''['"]R\\\$|'USD'|'BRL'|'EUR' ''');
    final violations = <String>[];

    for (final file in dartFiles) {
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (currencyPattern.hasMatch(lines[i]) &&
            !file.path.contains('currency_formatter') &&
            !lines[i].contains('// ignore: hardcoded')) {
          violations.add('${file.path}:${i + 1}: ${lines[i].trim()}');
        }
      }
    }

    expect(violations, isEmpty,
        reason: 'Hardcoded currency symbols found:\n${violations.join('\n')}');
  });
}
