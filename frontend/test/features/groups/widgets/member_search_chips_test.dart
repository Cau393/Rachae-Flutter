import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/core/providers/core_providers.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/groups/widgets/member_search_chips.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

Dio _dioWithSearchHandler({
  required List<Map<String, dynamic>> results,
  void Function(String q)? onQueried,
}) {
  final dio = Dio(
    BaseOptions(baseUrl: 'http://localhost/api/v1/'),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (RequestOptions request, RequestInterceptorHandler handler) {
        if (request.uri.path.contains('users/search')) {
          final String? q = request.uri.queryParameters['q'];
          if (q != null) {
            onQueried?.call(q);
          }
          return handler.resolve(
            Response<dynamic>(
              requestOptions: request,
              statusCode: 200,
              data: results,
            ),
          );
        }
        return handler.reject(
          DioException(
            requestOptions: request,
            error: 'unexpected path',
          ),
        );
      },
    ),
  );
  return dio;
}

void main() {
  Future<void> pumpWidget(
    WidgetTester tester, {
    required Widget child,
    required Dio dio,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dioProvider.overrideWithValue(dio),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('MemberSearchChips', () {
    testWidgets('typing fewer than 3 characters does not call search',
        (tester) async {
      var queries = 0;
      final dio = _dioWithSearchHandler(
        results: const [],
        onQueried: (_) => queries++,
      );
      await pumpWidget(
        tester,
        dio: dio,
        child: MemberSearchChips(onChanged: (_) {}),
      );

      await tester.enterText(find.byType(TextField), 'ab');
      await tester.pump(const Duration(milliseconds: 400));
      expect(queries, 0);
    });

    testWidgets('typing 3+ characters triggers search after debounce',
        (tester) async {
      var queries = 0;
      String? lastQ;
      final dio = _dioWithSearchHandler(
        results: const [],
        onQueried: (q) {
          queries++;
          lastQ = q;
        },
      );
      await pumpWidget(
        tester,
        dio: dio,
        child: MemberSearchChips(onChanged: (_) {}),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 400));
      expect(queries, 1);
      expect(lastQ, 'abc');
    });

    testWidgets('selecting a result adds InputChip and calls onChanged',
        (tester) async {
      final dio = _dioWithSearchHandler(
        results: [
          <String, dynamic>{
            'id': '11111111-1111-1111-1111-111111111111',
            'display_name': 'Alice',
            'email': 'a@a.com',
            'phone': null,
            'avatar_url': null,
          },
        ],
      );
      final calls = <List<String>>[];
      await pumpWidget(
        tester,
        dio: dio,
        child: MemberSearchChips(
          onChanged: (ids) => calls.add(List<String>.from(ids)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsOneWidget);
      expect(calls.last, ['11111111-1111-1111-1111-111111111111']);
    });

    testWidgets('chip delete removes user and updates onChanged',
        (tester) async {
      final dio = _dioWithSearchHandler(
        results: [
          <String, dynamic>{
            'id': '11111111-1111-1111-1111-111111111111',
            'display_name': 'Alice',
            'email': 'a@a.com',
            'phone': null,
            'avatar_url': null,
          },
        ],
      );
      final calls = <List<String>>[];
      await pumpWidget(
        tester,
        dio: dio,
        child: MemberSearchChips(
          onChanged: (ids) => calls.add(List<String>.from(ids)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsNothing);
      expect(calls.last, isEmpty);
    });

    testWidgets('selecting same user twice does not duplicate chip',
        (tester) async {
      final dio = _dioWithSearchHandler(
        results: [
          <String, dynamic>{
            'id': '11111111-1111-1111-1111-111111111111',
            'display_name': 'Alice',
            'email': 'a@a.com',
            'phone': null,
            'avatar_url': null,
          },
        ],
      );
      final calls = <List<String>>[];
      await pumpWidget(
        tester,
        dio: dio,
        child: MemberSearchChips(
          onChanged: (ids) => calls.add(List<String>.from(ids)),
        ),
      );

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'abc');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Alice').last);
      await tester.pumpAndSettle();

      expect(find.byType(InputChip), findsOneWidget);
      expect(
        calls.where((c) => c.contains('11111111-1111-1111-1111-111111111111'))
            .length,
        1,
      );
    });
  });
}
