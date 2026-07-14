import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/friends/screens/friends_screen.dart';
import 'package:frontend/features/friends/widgets/friend_card.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

void main() {
  FriendModel friend({
    required String id,
    required String name,
    required String email,
  }) =>
      FriendModel.fromJson(<String, dynamic>{
        'id': id,
        'display_name': name,
        'email': email,
        'phone': null,
        'avatar_url': null,
      });

  final friendA = friend(
    id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
    name: 'Alice Alpha',
    email: 'alice@example.com',
  );
  final friendB = friend(
    id: 'bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb',
    name: 'Bob Beta',
    email: 'bob@example.com',
  );

  void setPhysicalSize(WidgetTester tester, ui.Size size) {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
  }

  void resetPhysicalSize(WidgetTester tester) {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  GoRouter buildRouter() {
    return GoRouter(
      initialLocation: '/friends',
      routes: [
        GoRoute(
          path: '/friends',
          builder: (context, state) => const FriendsScreen(),
        ),
        GoRoute(
          path: '/friends/:id',
          builder: (context, state) => Scaffold(
            body: Text('detail:${state.pathParameters['id']}'),
          ),
        ),
      ],
    );
  }

  Future<void> pumpFriends(
    WidgetTester tester, {
    required GoRouter router,
    required List<Override> overrides,
    bool settle = true,
  }) async {
    setPhysicalSize(tester, const ui.Size(400, 900));
    addTearDown(() => resetPhysicalSize(tester));

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }

  testWidgets('loading: spinner, no FriendCard', (tester) async {
    final completer = Completer<List<FriendModel>>();
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      settle: false,
      overrides: [
        friendsProvider.overrideWith((ref) => completer.future),
      ],
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(FriendCard), findsNothing);
  });

  testWidgets('empty: friendsEmpty text', (tester) async {
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      overrides: [
        friendsProvider.overrideWith((ref) async => <FriendModel>[]),
      ],
    );

    expect(find.text('No friends yet. Invite someone!'), findsOneWidget);
    expect(find.byType(FriendCard), findsNothing);
  });

  testWidgets('two-item list: two FriendCard widgets', (tester) async {
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      overrides: [
        friendsProvider.overrideWith((ref) async => [friendA, friendB]),
      ],
    );

    expect(find.byType(FriendCard), findsNWidgets(2));
  });

  testWidgets('tapping card navigates to /friends/{id}', (tester) async {
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      overrides: [
        friendsProvider.overrideWith((ref) async => [friendA]),
      ],
    );

    await tester.tap(find.text('Alice Alpha'));
    await tester.pumpAndSettle();

    expect(find.textContaining('detail:aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa'),
        findsOneWidget);
  });

  testWidgets('AppBar has person_add IconButton', (tester) async {
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      overrides: [
        friendsProvider.overrideWith((ref) async => []),
      ],
    );

    expect(find.byIcon(Icons.person_add), findsOneWidget);
  });

  testWidgets('filter by name: one card when query matches single friend',
      (tester) async {
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      overrides: [
        friendsProvider.overrideWith((ref) async => [friendA, friendB]),
      ],
    );

    final field = find.byType(TextField);
    expect(field, findsWidgets);
    await tester.enterText(field.first, 'Bob');
    await tester.pump();

    expect(find.byType(FriendCard), findsOneWidget);
    expect(find.text('Bob Beta'), findsOneWidget);
    expect(find.text('Alice Alpha'), findsNothing);
  });

  testWidgets('RefreshIndicator is present', (tester) async {
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      overrides: [
        friendsProvider.overrideWith((ref) async => [friendA]),
      ],
    );

    expect(find.byType(RefreshIndicator), findsOneWidget);
  });

  testWidgets('error: errorGeneric and retry button', (tester) async {
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      overrides: [
        friendsProvider.overrideWith(
          (ref) => Future<List<FriendModel>>.error(Exception('net')),
        ),
      ],
    );

    expect(find.textContaining('Something went wrong'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('filtered empty shows noResultsLabel', (tester) async {
    final router = buildRouter();
    await pumpFriends(
      tester,
      router: router,
      overrides: [
        friendsProvider.overrideWith((ref) async => [friendA, friendB]),
      ],
    );

    await tester.enterText(find.byType(TextField).first, 'zzz');
    await tester.pump();

    expect(find.text('No results found.'), findsOneWidget);
    expect(find.byType(FriendCard), findsNothing);
  });
}
