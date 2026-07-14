import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/auth/auth_notifier.dart';
import 'package:frontend/features/auth/auth_state.dart';
import 'package:frontend/features/auth/screens/splash_screen.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';
import 'package:frontend/features/dashboard/screens/dashboard_screen.dart';

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(this._state);
  final AuthState _state;

  @override
  Future<AuthState> build() async => _state;
}

class MockUser extends Mock implements User {}

void main() {
  late MockUser mockUser;

  setUp(() {
    mockUser = MockUser();
  });

  /// Must match [AppLocalizations.splashLoading] for `locale: pt_BR`.
  const splashLoadingPtBr = 'Carregando...';

  /// [CircularProgressIndicator] animates forever; never use [WidgetTester.pumpAndSettle].
  Future<void> pumpSplashWithAuth(
    WidgetTester tester,
    AuthState authState,
  ) async {
    final container = ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(() => FakeAuthNotifier(authState)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SplashScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  void expectSplashChrome() {
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.bySemanticsLabel(splashLoadingPtBr), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(TextFormField), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
  }

  group('SplashScreen rendering', () {
    testWidgets('AuthState.initial shows loading chrome', (tester) async {
      await pumpSplashWithAuth(tester, const AuthState.initial());
      expectSplashChrome();
    });

    testWidgets('AuthState.loading shows loading chrome', (tester) async {
      await pumpSplashWithAuth(tester, const AuthState.loading());
      expectSplashChrome();
    });

    testWidgets('AuthState.authenticated shows loading chrome', (tester) async {
      await pumpSplashWithAuth(tester, AuthState.authenticated(user: mockUser));
      expectSplashChrome();
    });

    testWidgets('AuthState.unauthenticated shows loading chrome', (
      tester,
    ) async {
      await pumpSplashWithAuth(tester, const AuthState.unauthenticated());
      expectSplashChrome();
    });
  });

  group('SplashScreen loading state (no GoRouter)', () {
    testWidgets('stays mounted with visible indicator when auth is loading', (
      tester,
    ) async {
      await pumpSplashWithAuth(tester, const AuthState.loading());
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('SplashScreen router interaction', () {
    testWidgets(
      'redirect reaches dashboard when authenticated (router, not SplashScreen.go)',
      (tester) async {
        // Resolve auth before the first redirect so we never mount LoginPage (Supabase off in tests).
        final container = ProviderContainer(
          overrides: [
            authNotifierProvider.overrideWith(
              () => FakeAuthNotifier(AuthState.authenticated(user: mockUser)),
            ),
          ],
        );
        addTearDown(container.dispose);
        await container.read(authNotifierProvider.future);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) {
                return MaterialApp.router(
                  theme: AppTheme.light,
                  locale: const Locale('pt', 'BR'),
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  routerConfig: ref.watch(appRouterProvider),
                );
              },
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(DashboardScreen), findsOneWidget);
      },
    );
  });

  group('SplashScreen theme compliance', () {
    testWidgets('Scaffold uses AppTheme.light surface for background', (
      tester,
    ) async {
      await pumpSplashWithAuth(tester, const AuthState.loading());
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.backgroundColor, AppTheme.light.colorScheme.surface);
    });
  });

}
