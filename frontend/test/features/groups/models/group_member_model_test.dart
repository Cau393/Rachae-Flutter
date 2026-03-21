import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/groups/models/group_member_model.dart';

void main() {
  const joinedAt = '2025-02-01T10:00:00.000Z';

  const fullJson = <String, dynamic>{
    'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'display_name': 'Ada',
    'avatar_url': 'https://example.com/a.png',
    'role': 'ADMIN',
    'joined_at': joinedAt,
    'invited_by': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
  };

  test('fromJson maps all fields', () {
    final m = GroupMemberModel.fromJson(fullJson);
    expect(m.userId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
    expect(m.displayName, 'Ada');
    expect(m.avatarUrl, 'https://example.com/a.png');
    expect(m.role, 'ADMIN');
    expect(m.joinedAt, DateTime.parse(joinedAt));
    expect(m.invitedBy, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
  });

  test('fromJson allows null avatar_url and invited_by', () {
    final m = GroupMemberModel.fromJson({
      'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'display_name': 'Bob',
      'avatar_url': null,
      'role': 'MEMBER',
      'joined_at': joinedAt,
      'invited_by': null,
    });
    expect(m.avatarUrl, isNull);
    expect(m.invitedBy, isNull);
  });

  test('isAdmin, isMember, isViewer are mutually exclusive for ADMIN', () {
    final m = GroupMemberModel.fromJson(fullJson);
    expect(m.isAdmin, isTrue);
    expect(m.isMember, isFalse);
    expect(m.isViewer, isFalse);
  });

  test('isAdmin, isMember, isViewer are mutually exclusive for MEMBER', () {
    final m = GroupMemberModel.fromJson({
      ...fullJson,
      'role': 'MEMBER',
    });
    expect(m.isAdmin, isFalse);
    expect(m.isMember, isTrue);
    expect(m.isViewer, isFalse);
  });

  test('isAdmin, isMember, isViewer are mutually exclusive for VIEWER', () {
    final m = GroupMemberModel.fromJson({
      ...fullJson,
      'role': 'VIEWER',
    });
    expect(m.isAdmin, isFalse);
    expect(m.isMember, isFalse);
    expect(m.isViewer, isTrue);
  });
}
