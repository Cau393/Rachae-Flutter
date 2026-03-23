import 'api_base_url_stub.dart'
    if (dart.library.html) 'api_base_url_html.dart' as impl;

String webApiBaseUrl() => impl.webApiBaseUrl();
