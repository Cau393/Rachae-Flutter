import 'package:dio/dio.dart';

/// Web: no-op. Browsers terminate TLS themselves and don't expose a
/// certificate-inspection hook to Dart on web.
void configureCertPinning(Dio dio) {}
