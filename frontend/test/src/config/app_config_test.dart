import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/src/config/app_config.dart';

void main() {
  test('oauthRedirectUri returns custom scheme when kIsWeb is false', () {
    expect(AppConfig.oauthRedirectUri(), AppConfig.iosRedirectUrl);
  });
}
