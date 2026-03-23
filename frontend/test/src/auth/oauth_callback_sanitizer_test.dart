import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/src/auth/oauth_callback_sanitizer.dart';

void main() {
  test('detects callback auth params in query', () {
    final uri = Uri.parse(
      'http://192.168.1.114:61523/login?error=server_error&error_code=unexpected_failure',
    );

    expect(shouldSanitizeOAuthCallbackUri(uri), isTrue);
  });

  test('removes auth callback params and preserves invite token', () {
    final uri = Uri.parse(
      'http://192.168.1.114:61523/login'
      '?invite_token=abc'
      '&error=server_error'
      '&error_code=unexpected_failure'
      '#error=server_error&error_description=Database+error+saving+new+user&sb=',
    );

    final sanitized = sanitizeOAuthCallbackUri(uri);

    expect(
      sanitized.toString(),
      'http://192.168.1.114:61523/login?invite_token=abc',
    );
  });

  test('returns false when there are no auth callback params', () {
    final uri = Uri.parse('http://192.168.1.114:61523/login?invite_token=abc');

    expect(shouldSanitizeOAuthCallbackUri(uri), isFalse);
  });
}
