import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/widgets/friend_card.dart';

void main() {
  FriendModel friend({
    String? avatarUrl,
    String displayName = 'Alice',
    String email = 'alice@example.com',
  }) =>
      FriendModel.fromJson(<String, dynamic>{
        'id': 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
        'display_name': displayName,
        'email': email,
        'phone': null,
        'avatar_url': avatarUrl,
      });

  Future<void> pumpCard(
    WidgetTester tester, {
    required FriendModel model,
    VoidCallback? onTap,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: FriendCard(model: model, onTap: onTap ?? () {}),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('with avatarUrl null: CircleAvatar shows initials text', (tester) async {
    await pumpCard(tester, model: friend(avatarUrl: null));
    expect(find.byType(CircleAvatar), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
  });

  testWidgets('with avatarUrl non-null: CircleAvatar uses CachedNetworkImage', (tester) async {
    const url = 'https://cdn.example/avatar.png';
    await pumpCard(tester, model: friend(avatarUrl: url));
    expect(find.byType(CachedNetworkImage), findsOneWidget);
    final image = tester.widget<CachedNetworkImage>(find.byType(CachedNetworkImage));
    expect(image.imageUrl, url);
  });

  testWidgets('displayName text is present', (tester) async {
    await pumpCard(tester, model: friend(displayName: 'Bob Smith'));
    expect(find.text('Bob Smith'), findsOneWidget);
  });

  testWidgets('email text is present', (tester) async {
    await pumpCard(tester, model: friend(email: 'bob@example.org'));
    expect(find.text('bob@example.org'), findsOneWidget);
  });

  testWidgets('tapping calls onTap exactly once', (tester) async {
    var taps = 0;
    await pumpCard(
      tester,
      model: friend(),
      onTap: () => taps++,
    );
    await tester.tap(find.byType(FriendCard));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('chevron_right icon is present', (tester) async {
    await pumpCard(tester, model: friend());
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });
}
