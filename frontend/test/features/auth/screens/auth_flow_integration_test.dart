import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/auth/screens/login_screen.dart';
import 'package:frontend/features/auth/screens/splash_screen.dart';
import 'package:frontend/features/dashboard/screens/dashboard_screen.dart';
import 'package:frontend/src/app.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

class MockUser extends Mock implements User {}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

/// Completes Google sign-in in tests — drives router from /login to /dashboard.
class SignInOnGoogleAuthNotifier extends AuthNotifier {
  SignInOnGoogleAuthNotifier(this._user);
  final User _user;

  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();

  @override
  Future<void> signInWithGoogle() async {
    state = AsyncData(AuthState.authenticated(user: _user));
  }
}

void clearTestPlatform() {
  debugDefaultTargetPlatformOverride = null;
}

/// [SplashScreen] and overlays may host non-idling [CircularProgressIndicator]s.
Future<void> pumpRachaeApp(
  WidgetTester tester,
  AuthNotifier Function() createNotifier,
) async {
  final container = ProviderContainer(
    overrides: [
      authNotifierProvider.overrideWith(createNotifier),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authNotifierProvider.future);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const RachaeApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser();
  });

  group('Auth flow integration (RachaeApp)', () {
    testWidgets(
      'unauthenticated: LoginScreen visible, SplashScreen not mounted',
      (tester) async {
        await pumpRachaeApp(
          tester,
          () => FakeAuthNotifier(const AuthState.unauthenticated()),
        );

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(find.byType(SplashScreen), findsNothing);
      },
    );

    testWidgets('authenticated: LoginScreen not shown; Dashboard visible', (
      tester,
    ) async {
      await pumpRachaeApp(
        tester,
        () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
      );

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets(
      'after Google tap: unauthenticated → authenticated leaves LoginScreen',
      (tester) async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

        await pumpRachaeApp(
          tester,
          () => SignInOnGoogleAuthNotifier(mockUser),
        );

        expect(find.byType(LoginScreen), findsOneWidget);

        final ctx = tester.element(find.byType(LoginScreen));
        final l10n = AppLocalizations.of(ctx)!;

        await tester.tap(find.bySemanticsLabel(l10n.signInWithGoogle));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        await tester.pump();

        expect(find.byType(LoginScreen), findsNothing);
        expect(find.byType(DashboardScreen), findsOneWidget);

        clearTestPlatform();
      },
    );
  });
}
