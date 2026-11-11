import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:web/web.dart' as web;

import 'analytics_transport_base.dart';

/// The web: Google's own tag (gtag.js), so GA gets the page, browser, country
/// and campaign details without any server-side help. The tag is added to the
/// page when the app starts, never baked into `index.html`.
AnalyticsTransport createTransport() => WebAnalyticsTransport();

class WebAnalyticsTransport implements AnalyticsTransport {
  bool _started = false;

  @override
  Future<void> start({
    required String measurementId,
    String? apiSecret,
    required bool granted,
  }) async {
    final head = web.document.head;
    if (head == null) return;
    // gtag() has to push the `arguments` object itself, which only a plain
    // JavaScript function can do.
    final bootstrap = web.HTMLScriptElement()
      ..text =
          'window.dataLayer = window.dataLayer || [];'
          'function gtag(){dataLayer.push(arguments);}'
          "gtag('consent','default',{analytics_storage:'${granted ? 'granted' : 'denied'}'});"
          "gtag('js', new Date());"
          // The app reports its own screens; GA must not also count the one
          // real page load.
          "gtag('config','$measurementId',{send_page_view:false});";
    head.append(bootstrap);
    final tag = web.HTMLScriptElement()
      ..async = true
      ..src =
          'https://www.googletagmanager.com/gtag/js?id=${Uri.encodeQueryComponent(measurementId)}';
    head.append(tag);
    _started = true;
  }

  void _gtag(List<JSAny?> args) {
    if (!_started) return;
    web.window.callMethod(
      'gtag'.toJS,
      args[0],
      args[1],
      args.length > 2 ? args[2] : null,
    );
  }

  @override
  void setConsent(bool granted) => _gtag([
    'consent'.toJS,
    'update'.toJS,
    {'analytics_storage': granted ? 'granted' : 'denied'}.jsify(),
  ]);

  @override
  void send(AnalyticsEvent event) =>
      _gtag(['event'.toJS, event.name.toJS, event.params.jsify()]);
}
