import 'oauth_callback_history_cleanup_stub.dart'
    if (dart.library.html) 'oauth_callback_history_cleanup_web.dart' as impl;

void cleanupOAuthCallbackHistory() => impl.cleanupOAuthCallbackHistory();
