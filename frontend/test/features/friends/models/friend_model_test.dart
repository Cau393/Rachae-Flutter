import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/friends/models/friend_model.dart';

void main() {
  test('fromJson parses all fields; phone is nullable', () {
    final withPhone = FriendModel.fromJson({
      'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      'display_name': 'Alice',
      'email': 'alice@example.com',
      'phone': '+5511999999999',
      'avatar_url': 'https://cdn.example/a.png',
    });
    expect(withPhone.id, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
    expect(withPhone.displayName, 'Alice');
    expect(withPhone.email, 'alice@example.com');
    expect(withPhone.phone, '+5511999999999');
    expect(withPhone.avatarUrl, 'https://cdn.example/a.png');

    final noPhone = FriendModel.fromJson({
      'id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
      'display_name': 'Bob',
      'email': 'bob@example.com',
      'phone': null,
      'avatar_url': null,
    });
    expect(noPhone.phone, isNull);
    expect(noPhone.avatarUrl, isNull);
  });

  test('initials returns uppercase first character of displayName', () {
    expect(
      FriendModel.fromJson({
        'id': '1',
        'display_name': 'carlos',
        'email': 'c@x.com',
        'phone': null,
        'avatar_url': null,
      }).initials,
      'C',
    );
  });

  test('equality is by id only', () {
    final a = FriendModel.fromJson({
      'id': 'same-id',
      'display_name': 'A',
      'email': 'a@x.com',
      'phone': null,
      'avatar_url': null,
    });
    final b = FriendModel.fromJson({
      'id': 'same-id',
      'display_name': 'B',
      'email': 'b@x.com',
      'phone': '+1',
      'avatar_url': 'x',
    });
    expect(a, equals(b));
    expect(a.hashCode, equals(b.hashCode));

    final c = FriendModel.fromJson({
      'id': 'other-id',
      'display_name': 'A',
      'email': 'a@x.com',
      'phone': null,
      'avatar_url': null,
    });
    expect(a, isNot(equals(c)));
  });
}
