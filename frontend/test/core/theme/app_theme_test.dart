import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// import 'package:frontend/core/theme/app_theme.dart'; // TODO: GREEN
import 'package:frontend/core/theme/app_theme.dart';

void main() {
  final expectedSeed = const Color(0xFF246BFD);
  final referenceScheme = ColorScheme.fromSeed(seedColor: expectedSeed);

  test('light theme uses Material 3', () {
    expect(AppTheme.light.useMaterial3, isTrue);
  });

  test('primary seed color is Color(0xFF246BFD)', () {
    expect(
      AppTheme.light.colorScheme.primary,
      referenceScheme.primary,
    );
  });

  test('dark theme uses Material 3', () {
    expect(AppTheme.dark.useMaterial3, isTrue);
  });
}
