// Conditional export: web uses AdSense [WebAdsenseBanner]; VM uses stub.
export 'web_sidebar_ad_stub.dart'
    if (dart.library.html) 'web_sidebar_ad_web.dart';
