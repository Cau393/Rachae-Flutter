import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/expenses/widgets/receipt_gallery.dart';
import 'package:frontend/src/l10n/generated/app_localizations.dart';

/// Same minimal PNG as [receipt_upload_row_test.dart].
final _minimalPngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGhzNcFzQAAAABJRU5ErkJggg==',
);

class MockHttpClient extends Mock implements HttpClient {}

class MockHttpClientRequest extends Mock implements HttpClientRequest {}

class MockHttpClientResponse extends Mock implements HttpClientResponse {}

class MockHttpHeaders extends Mock implements HttpHeaders {}

/// Returns an [HttpClient] that serves [_minimalPngBytes] for every GET.
MockHttpClient createTestPngHttpClient(List<int> png) {
  final client = MockHttpClient();

  when(() => client.getUrl(any())).thenAnswer((_) {
    final request = MockHttpClientRequest();
    final response = MockHttpClientResponse();
    final headers = MockHttpHeaders();

    when(() => request.headers).thenReturn(headers);
    when(() => request.close()).thenAnswer((_) async => response);

    when(() => response.compressionState)
        .thenReturn(HttpClientResponseCompressionState.notCompressed);
    when(() => response.contentLength).thenReturn(png.length);
    when(() => response.statusCode).thenReturn(HttpStatus.ok);
    when(() => response.reasonPhrase).thenReturn('OK');
    when(() => response.isRedirect).thenReturn(false);
    when(() => response.headers).thenReturn(headers);

    when(
      () => response.listen(
        any(),
        onError: any(named: 'onError'),
        onDone: any(named: 'onDone'),
        cancelOnError: any(named: 'cancelOnError'),
      ),
    ).thenAnswer((invocation) {
      final onData =
          invocation.positionalArguments[0] as void Function(List<int>)?;
      final onDone =
          invocation.namedArguments[#onDone] as void Function()?;
      final onError = invocation.namedArguments[#onError];
      final cancelOnError =
          invocation.namedArguments[#cancelOnError] as bool?;

      return Stream<List<int>>.fromIterable(<List<int>>[png]).listen(
        onData,
        onDone: onDone,
        onError: onError,
        cancelOnError: cancelOnError,
      );
    });

    return Future<HttpClientRequest>.value(request);
  });

  return client;
}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com/'));
  });

  Widget app(Widget home) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: home),
    );
  }

  testWidgets('empty list shows expenseDetailNoReceipts', (tester) async {
    await tester.pumpWidget(
      app(const ReceiptGallery(receiptUrls: [])),
    );
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(ReceiptGallery)),
    )!;
    expect(find.text(l10n.expenseDetailNoReceipts), findsOneWidget);
  });

  testWidgets('two URLs render two Image widgets with NetworkImage',
      (tester) async {
    await HttpOverrides.runZoned(
      () async {
        await tester.pumpWidget(
          app(
            const ReceiptGallery(
              receiptUrls: [
                'https://example.com/a.png',
                'https://example.com/b.png',
              ],
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
      createHttpClient: (_) => createTestPngHttpClient(_minimalPngBytes),
    );

    bool isNetworkImage(Image w) => w.image is NetworkImage;

    final images =
        tester.widgetList<Image>(find.byType(Image)).where(isNetworkImage);
    expect(images, hasLength(2));
  });
}
