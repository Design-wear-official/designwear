// Picks the transport for the platform: gtag.js on the web, the Measurement
// Protocol over HTTP everywhere else (Android, iOS and desktop).
export 'analytics_transport_base.dart';
export 'analytics_transport_http.dart'
    if (dart.library.js_interop) 'analytics_transport_web.dart';
