import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/ad_banner.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/friends/models/friend_model.dart';
import 'package:frontend/features/friends/providers/friends_provider.dart';
import 'package:frontend/features/settlements/models/transaction_model.dart';
import 'package:frontend/features/settlements/providers/settlement_repository_provider.dart';
import 'package:frontend/features/settlements/repositories/settlement_repository.dart';
import 'package:frontend/features/settlements/screens/settle_up_screen.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class MockUser extends Mock implements User {}

class _MockSettlementRepository extends Mock implements SettlementRepository {}

void main() {
  const receiverId = 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa';
  const currentUid = 'cccccccc-cccc-cccc-cccc-cccccccccccc';

  late MockUser mockUser;
  late _MockSettlementRepository mockSettlement;

  FriendModel friend() => FriendModel.fromJson(<String, dynamic>{
        'id': receiverId,
        'display_name': 'Pat Friend',
        'email': 'pat@example.com',
        'phone': null,
        'avatar_url': null,
      });

  TransactionModel transaction() => TransactionModel.fromJson(<String, dynamic>{
        'id': 'eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee',
        'group_id': null,
        'payer': <String, dynamic>{
          'user_id': currentUid,
          'display_name': 'Me',
          'avatar_url': null,
        },
        'receiver': <String, dynamic>{
          'user_id': receiverId,
          'display_name': 'Pat Friend',
          'avatar_url': null,
        },
        'amount': '10.00',
        'currency': 'BRL',
        'note': null,
        'is_confirmed': false,
        'is_disputed': false,
        'created_at': '2026-03-20T15:30:00Z',
      });

  List<Override> baseOverrides() => [
        friendsProvider.overrideWith((ref) async => [friend()]),
        settlementRepositoryProvider.overrideWithValue(mockSettlement),
        authNotifierProvider.overrideWith(
          () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
        ),
      ];

  Future<void> pumpSettle(
    WidgetTester tester, {
    required GoRouter router,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: baseOverrides(),
        child: MaterialApp.router(
          theme: AppTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    mockUser = MockUser();
    when(() => mockUser.id).thenReturn(currentUid);
    when(() => mockUser.email).thenReturn('payer@test.com');
    when(() => mockUser.userMetadata).thenReturn(null);
    mockSettlement = _MockSettlementRepository();
    when(
      () => mockSettlement.createTransaction(
        receiverId: any(named: 'receiverId'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        groupId: any(named: 'groupId'),
        note: any(named: 'note'),
      ),
    ).thenAnswer((_) async => transaction());
  });

  test('_handleRecord uses mounted guard in finally', () {
    final path =
        'lib/features/settlements/screens/settle_up_screen.dart';
    final root = Directory.current.path.endsWith('frontend')
        ? Directory.current
        : Directory('${Directory.current.path}/frontend');
    final content = File('${root.path}/$path').readAsStringSync();
    expect(content, contains('if (mounted)'));
    expect(content, contains('_isLoading = false'));
  });

  testWidgets('pre-filled amount appears in AmountField', (tester) async {
    final router = GoRouter(
      initialLocation:
          '/settle?receiver_id=$receiverId&amount=99.50&currency=BRL',
      routes: [
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );
    await pumpSettle(tester, router: router);

    expect(find.widgetWithText(TextField, '99,50'), findsOneWidget);
  });

  testWidgets('pre-filled receiver_id shows receiver row, not dropdown',
      (tester) async {
    final router = GoRouter(
      initialLocation:
          '/settle?receiver_id=$receiverId&amount=10&currency=BRL',
      routes: [
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );
    await pumpSettle(tester, router: router);

    expect(find.text('Pat Friend'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);
  });

  testWidgets('suggested line when amount came from query', (tester) async {
    final router = GoRouter(
      initialLocation:
          '/settle?receiver_id=$receiverId&amount=25&currency=BRL',
      routes: [
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );
    await pumpSettle(tester, router: router);

    expect(find.textContaining('Suggested'), findsOneWidget);
  });

  testWidgets('Record button disabled when amount empty', (tester) async {
    final router = GoRouter(
      initialLocation: '/settle?receiver_id=$receiverId&currency=BRL',
      routes: [
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );
    await pumpSettle(tester, router: router);

    final button =
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('Record button disabled when receiver empty', (tester) async {
    final router = GoRouter(
      initialLocation: '/settle?amount=10&currency=BRL',
      routes: [
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );
    await pumpSettle(tester, router: router);

    final button =
        tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
  });

  testWidgets('tapping Record calls createTransaction with valid fields',
      (tester) async {
    final router = GoRouter(
      initialLocation:
          '/settle?receiver_id=$receiverId&amount=10.00&currency=BRL',
      routes: [
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );
    await pumpSettle(tester, router: router);

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    verify(
      () => mockSettlement.createTransaction(
        receiverId: receiverId,
        amount: '10.00',
        currency: 'BRL',
        groupId: null,
        note: null,
      ),
    ).called(1);
  });

  testWidgets('success shows snackbar and pops', (tester) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(
                '/settle?receiver_id=$receiverId&amount=10&currency=BRL',
              ),
              child: const Text('OPEN_SETTLE'),
            ),
          ),
        ),
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );

    await pumpSettle(tester, router: router);
    await tester.tap(find.text('OPEN_SETTLE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(
      find.text('Payment recorded! Awaiting confirmation.'),
      findsOneWidget,
    );
    expect(find.text('OPEN_SETTLE'), findsOneWidget);
  });

  testWidgets('AsyncError shows error snackbar and stays on screen',
      (tester) async {
    when(
      () => mockSettlement.createTransaction(
        receiverId: any(named: 'receiverId'),
        amount: any(named: 'amount'),
        currency: any(named: 'currency'),
        groupId: any(named: 'groupId'),
        note: any(named: 'note'),
      ),
    ).thenThrow(Exception('network'));

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push(
                '/settle?receiver_id=$receiverId&amount=10&currency=BRL',
              ),
              child: const Text('OPEN_SETTLE'),
            ),
          ),
        ),
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );

    await pumpSettle(tester, router: router);
    await tester.tap(find.text('OPEN_SETTLE'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Record payment'));
    await tester.pumpAndSettle();

    expect(find.text('Error recording payment.'), findsOneWidget);
    expect(find.text('Settle up'), findsOneWidget);
  });

  testWidgets('no AdBanner in tree', (tester) async {
    final router = GoRouter(
      initialLocation:
          '/settle?receiver_id=$receiverId&amount=1&currency=BRL',
      routes: [
        GoRoute(
          path: '/settle',
          builder: (_, _) => const SettleUpScreen(),
        ),
      ],
    );
    await pumpSettle(tester, router: router);

    expect(find.byType(AdBanner), findsNothing);
  });
}
