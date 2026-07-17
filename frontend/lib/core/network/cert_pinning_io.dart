import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'cert_pinning.dart';

void configureCertPinning(Dio dio) {
  if (!kEnableCertPinning) return;
  final adapter = dio.httpClientAdapter;
  if (adapter is! IOHttpClientAdapter) return;

  adapter.createHttpClient = () {
    // `badCertificateCallback` only fires for certs that already fail
    // default trust validation — a legitimately CA-signed cert (the normal
    // case) would never reach it, so pinning would silently do nothing.
    // `withTrustedRoots: false` makes every connection untrusted by
    // default, forcing every request through the callback below so the
    // pin check actually runs.
    final client = HttpClient(
      context: SecurityContext(withTrustedRoots: false),
    );
    client.badCertificateCallback = (cert, host, port) {
      // This client is only wired into the shared API `Dio` instance
      // (`ApiClient`), which is scoped to `pinnedApiHost` via `baseUrl`. If
      // it's ever reused for another host (e.g. a signed S3/CDN URL),
      // requests to that host will fail closed here — extend the pin list
      // or the host check before doing that.
      if (host != pinnedApiHost) return false;
      final hash = base64.encode(sha256.convert(cert.der).bytes);
      return pinnedRailwayCertSha256Hashes.contains(hash);
    };
    return client;
  };
}
