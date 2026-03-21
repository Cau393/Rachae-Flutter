import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> userKeys(Map<String, dynamic> arb) =>
    arb.keys.where((k) => !k.startsWith('@')).toSet();

void main() {
  late Map<String, dynamic> ptBR;
  late Map<String, dynamic> en;

  setUpAll(() {
    final ptBRFile = File('lib/l10n/app_pt_BR.arb');
    final enFile = File('lib/l10n/app_en.arb');
    ptBR = jsonDecode(ptBRFile.readAsStringSync()) as Map<String, dynamic>;
    en = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  });

  test('pt_BR and en have identical key sets', () {
    final ptKeys = userKeys(ptBR);
    final enKeys = userKeys(en);
    final onlyInPt = ptKeys.difference(enKeys);
    final onlyInEn = enKeys.difference(ptKeys);
    expect(onlyInPt, isEmpty,
        reason: 'Keys in pt_BR but missing from en: $onlyInPt');
    expect(onlyInEn, isEmpty,
        reason: 'Keys in en but missing from pt_BR: $onlyInEn');
  });

  test('pt_BR has no empty string values (except adBannerFallback)', () {
    final violations = <String>[];
    for (final key in userKeys(ptBR)) {
      if (key == 'adBannerFallback') continue;
      final value = ptBR[key];
      if (value is String && value.trim().isEmpty) {
        violations.add(key);
      }
    }
    expect(violations, isEmpty,
        reason: 'Empty string values in pt_BR: $violations');
  });

  test('en has no empty string values (except adBannerFallback)', () {
    final violations = <String>[];
    for (final key in userKeys(en)) {
      if (key == 'adBannerFallback') continue;
      final value = en[key];
      if (value is String && value.trim().isEmpty) {
        violations.add(key);
      }
    }
    expect(violations, isEmpty,
        reason: 'Empty string values in en: $violations');
  });

  test(
      'every parameterised key in pt_BR has a matching @key metadata block',
      () {
    final placeholderPattern = RegExp(r'\{(\w+)\}');
    for (final key in userKeys(ptBR)) {
      final value = ptBR[key];
      if (value is! String) continue;
      if (placeholderPattern.hasMatch(value)) {
        expect(
          ptBR.containsKey('@$key'),
          isTrue,
          reason:
              'Key "$key" has placeholders but missing @$key metadata',
        );
      }
    }
  });

  test('pt_BR @@locale is set to pt_BR', () {
    expect(ptBR['@@locale'], equals('pt_BR'));
  });

  test('total key count is at least 100', () {
    expect(userKeys(ptBR).length, greaterThanOrEqualTo(100));
  });
}
