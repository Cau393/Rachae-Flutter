import 'oauth_redirect_uri_stub.dart'
    if (dart.library.html) 'oauth_redirect_uri_html.dart' as impl;

/// Web: current browser origin + path (no query/fragment). See html impl.
String webOAuthRedirectUri() => impl.webOAuthRedirectUri();
