import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/groups/models/group_detail_model.dart';

void main() {
  const createdAt = '2025-03-01T08:00:00.000Z';

  final memberA = <String, dynamic>{
    'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'display_name': 'Ada',
    'avatar_url': null,
    'role': 'ADMIN',
    'joined_at': '2025-03-01T09:00:00.000Z',
    'invited_by': null,
  };

  final memberB = <String, dynamic>{
    'user_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'display_name': 'Bob',
    'avatar_url': 'https://example.com/b.png',
    'role': 'MEMBER',
    'joined_at': '2025-03-01T09:30:00.000Z',
    'invited_by': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
  };

  final balanceA = <String, dynamic>{
    'user_id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'display_name': 'Ada',
    'net_balance': '10.00',
  };

  final balanceB = <String, dynamic>{
    'user_id': 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    'display_name': 'Bob',
    'net_balance': '-10.00',
  };

  final fullDetailJson = <String, dynamic>{
    'id': '11111111-1111-1111-1111-111111111111',
    'name': 'Home group',
    'description': 'Shared flat',
    'type': 'home',
    'currency': 'BRL',
    'simplify_debts': true,
    'created_by': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    'members': [memberA, memberB],
    'net_balances': [balanceA, balanceB],
    'created_at': createdAt,
  };

  test('fromJson maps all fields and nested members and net_balances', () {
    final model = GroupDetailModel.fromJson(fullDetailJson);
    expect(model.id, '11111111-1111-1111-1111-111111111111');
    expect(model.name, 'Home group');
    expect(model.description, 'Shared flat');
    expect(model.type, 'home');
    expect(model.currency, 'BRL');
    expect(model.simplifyDebts, isTrue);
    expect(model.createdBy, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
    expect(model.members, hasLength(2));
    expect(model.members[0].userId, 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa');
    expect(model.members[1].displayName, 'Bob');
    expect(model.netBalances, hasLength(2));
    expect(model.netBalances[0].netBalance, '10.00');
    expect(model.netBalances[1].netBalance, '-10.00');
    expect(model.createdAt, DateTime.parse(createdAt));
  });

  test('fromJson handles null description', () {
    final model = GroupDetailModel.fromJson({
      ...fullDetailJson,
      'description': null,
    });
    expect(model.description, isNull);
  });

  test('fromJson handles omitted description key', () {
    final json = Map<String, dynamic>.from(fullDetailJson)..remove('description');
    final model = GroupDetailModel.fromJson(json);
    expect(model.description, isNull);
  });

  test('fromJson handles null net_balances', () {
    final model = GroupDetailModel.fromJson({
      ...fullDetailJson,
      'net_balances': null,
    });
    expect(model.netBalances, isEmpty);
  });

  test('fromJson handles omitted net_balances key', () {
    final json = Map<String, dynamic>.from(fullDetailJson)..remove('net_balances');
    final model = GroupDetailModel.fromJson(json);
    expect(model.netBalances, isEmpty);
  });

  test('fromJson handles empty net_balances list', () {
    final model = GroupDetailModel.fromJson({
      ...fullDetailJson,
      'net_balances': <dynamic>[],
    });
    expect(model.netBalances, isEmpty);
  });

  test('memberByUserId returns matching member', () {
    final model = GroupDetailModel.fromJson(fullDetailJson);
    final found = model.memberByUserId('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
    expect(found, isNotNull);
    expect(found!.userId, 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
    expect(found.role, 'MEMBER');
  });

  test('memberByUserId returns null for unknown id', () {
    final model = GroupDetailModel.fromJson(fullDetailJson);
    expect(
      model.memberByUserId('00000000-0000-0000-0000-000000000000'),
      isNull,
    );
  });

  test('memberByUserId returns first match when duplicates', () {
    final dup = Map<String, dynamic>.from(memberA)
      ..['user_id'] = 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb';
    final model = GroupDetailModel.fromJson({
      ...fullDetailJson,
      'members': [memberB, dup],
    });
    final found = model.memberByUserId('bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb');
    expect(found, isNotNull);
    expect(found!.displayName, 'Bob');
  });
}
