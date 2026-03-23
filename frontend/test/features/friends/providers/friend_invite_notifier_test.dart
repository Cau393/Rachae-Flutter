// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/features/friends/models/friend_invite_model.dart';
import 'package:frontend/features/friends/providers/friend_invite_notifier.dart';
import 'package:frontend/features/friends/providers/friends_repository_provider.dart';
import 'package:frontend/features/friends/repositories/friends_repository.dart';

class _MockFriendsRepository extends Mock implements FriendsRepository {}

void main() {
  // Must match [Clipboard]'s channel codec (`flutter/lib/src/services/clipboard.dart`).
  const channel = MethodChannel('flutter/platform', JSONMethodCodec());

  late _MockFriendsRepository mockRepo;
  late ProviderContainer container;
  String? capturedClipboardText;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    capturedClipboardText = null;
    mockRepo = _MockFriendsRepository();
    container = ProviderContainer(
      overrides: [friendsRepositoryProvider.overrideWithValue(mockRepo)],
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      if (call.method == 'Clipboard.setData') {
        final args = call.arguments as Map<dynamic, dynamic>;
        capturedClipboardText = args['text'] as String?;
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    container.dispose();
  });

  FriendInviteModel sampleInvite() => FriendInviteModel.fromJson(<String, dynamic>{
        'id': 'cccccccc-cccc-cccc-cccc-cccccccccccc',
        'email': null,
        'phone': null,
        'token': 'tok',
        'status': 'PENDING',
        'expires_at': '2026-12-31T23:59:59Z',
        'created_at': '2026-01-01T12:00:00Z',
        'invite_url': 'https://app.example/invite?token=tok',
      });

  test('sendInvite calls createInvite once', () async {
    final invite = sampleInvite();
    when(() => mockRepo.createInvite()).thenAnswer((_) async => invite);

    await container.read(friendInviteNotifierProvider.notifier).sendInvite();

    verify(() => mockRepo.createInvite()).called(1);
  });

  test('after success, Clipboard.setData is called with inviteUrl', () async {
    final invite = sampleInvite();
    when(() => mockRepo.createInvite()).thenAnswer((_) async => invite);

    await container.read(friendInviteNotifierProvider.notifier).sendInvite();

    expect(capturedClipboardText, invite.inviteUrl);
    expect(
      container.read(friendInviteNotifierProvider),
      isA<AsyncData<void>>(),
    );
  });
}
