import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('l10n.yaml exists and has correct configuration', () {
    final file = File('l10n.yaml');
    expect(file.existsSync(), isTrue);
    final content = file.readAsStringSync();
    expect(content.contains('arb-dir: lib/l10n'), isTrue);
    expect(content.contains('template-arb-file: app_pt_BR.arb'), isTrue);
    expect(content.contains('output-localization-file: app_localizations.dart'), isTrue);
  });

  test('app_pt_BR.arb file exists', () {
    expect(File('lib/l10n/app_pt_BR.arb').existsSync(), isTrue);
  });

  test('app_en.arb file exists', () {
    expect(File('lib/l10n/app_en.arb').existsSync(), isTrue);
  });

  test('generated app_localizations.dart exists', () {
    expect(
      File('lib/src/l10n/generated/app_localizations.dart').existsSync(),
      isTrue,
      reason: 'Run flutter gen-l10n and commit the generated files.',
    );
  });
}
