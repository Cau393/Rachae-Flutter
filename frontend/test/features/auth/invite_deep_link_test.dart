import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/features/auth/invite_deep_link.dart';
import 'package:frontend/features/auth/invite_deep_link_bootstrap.dart';
import 'package:frontend/src/config/app_config.dart';

void main() {
  group('parseInviteTokenFromIosCustomSchemeUri', () {
    test('returns token for io.supabase.rachae://invite?invite_token=...', () {
      final uri = Uri.parse(
        '${Uri.parse(AppConfig.iosRedirectUrl).scheme}://invite?invite_token=abc_token_1',
      );
      expect(parseInviteTokenFromIosCustomSchemeUri(uri), 'abc_token_1');
    });

    test('returns null for OAuth login-callback host', () {
      final uri = Uri.parse(AppConfig.iosRedirectUrl);
      expect(parseInviteTokenFromIosCustomSchemeUri(uri), isNull);
    });

    test('returns null for wrong scheme', () {
      final uri = Uri.parse('https://example.com/invite?invite_token=x');
      expect(parseInviteTokenFromIosCustomSchemeUri(uri), isNull);
    });

    test('returns null when token missing', () {
      final uri = Uri.parse(
        '${Uri.parse(AppConfig.iosRedirectUrl).scheme}://invite',
      );
      expect(parseInviteTokenFromIosCustomSchemeUri(uri), isNull);
    });
  });

  group('buildIosFriendInviteAppUri', () {
    test('includes invite host and query param', () {
      final u = buildIosFriendInviteAppUri('tok123');
      expect(u.scheme, Uri.parse(AppConfig.iosRedirectUrl).scheme);
      expect(u.host, 'invite');
      expect(u.queryParameters['invite_token'], 'tok123');
    });
  });

  group('inviteAwareInitialLocation', () {
    tearDown(() {
      pendingIosInviteTokenFromColdStart = null;
    });

    test('default is / when no pending token', () {
      pendingIosInviteTokenFromColdStart = null;
      expect(inviteAwareInitialLocation(), '/');
    });

    test('includes invite_token when pending token set', () {
      pendingIosInviteTokenFromColdStart = 'cold_tok';
      expect(inviteAwareInitialLocation(), '/login?invite_token=cold_tok');
    });
  });
}
