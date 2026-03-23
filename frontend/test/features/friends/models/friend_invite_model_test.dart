import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/friends/models/friend_invite_model.dart';

void main() {
  test('fromJson parses invite_url into inviteUrl and all fields', () {
    final m = FriendInviteModel.fromJson({
      'id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
      'email': 'invitee@example.com',
      'phone': '+5511888888888',
      'token': 'secret-token',
      'status': 'PENDING',
      'expires_at': '2026-12-31T23:59:59Z',
      'created_at': '2026-01-01T12:00:00Z',
      'invite_url': 'https://app.example/invite?token=secret-token',
    });
    expect(m.id, 'cccccccc-cccc-cccc-cccc-cccccccccccc');
    expect(m.email, 'invitee@example.com');
    expect(m.phone, '+5511888888888');
    expect(m.token, 'secret-token');
    expect(m.status, 'PENDING');
    expect(m.expiresAt.toUtc(), DateTime.utc(2026, 12, 31, 23, 59, 59));
    expect(m.createdAt.toUtc(), DateTime.utc(2026, 1, 1, 12, 0, 0));
    expect(m.inviteUrl, 'https://app.example/invite?token=secret-token');
  });

  test('fromJson allows null email', () {
    final m = FriendInviteModel.fromJson({
      'id': 'dddddddd-dddd-dddd-dddd-dddddddddddd',
      'email': null,
      'phone': '+5511777777777',
      'token': 't',
      'status': 'PENDING',
      'expires_at': '2026-06-15T00:00:00Z',
      'created_at': '2026-06-01T00:00:00Z',
      'invite_url': 'https://x/y',
    });
    expect(m.email, isNull);
  });

  test('fromJson allows null phone', () {
    final m = FriendInviteModel.fromJson({
      'id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
      'email': null,
      'phone': null,
      'token': 't',
      'status': 'PENDING',
      'expires_at': '2026-06-15T00:00:00Z',
      'created_at': '2026-06-01T00:00:00Z',
      'invite_url': 'https://x/y',
    });
    expect(m.phone, isNull);
  });
}
