import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'analytics_transport.dart';

/// Google Analytics (GA4) for the web, Android, iOS and desktop apps.
///
/// Switched on by `GA_MEASUREMENT_ID` in `.env` (looks like `G-XXXXXXXXXX`).
/// Android, iOS and desktop also need `GA_API_SECRET`, because they report
/// through GA4's Measurement Protocol; the web does not use it. Leave the id
/// blank and nothing is sent anywhere.
///
/// Only anonymous usage goes out: screens and shopping steps. Never a name,
/// email, phone number, address or anything typed into the app. The person can
/// switch it off in Profile; the choice is remembered on the device.
class Analytics extends ChangeNotifier {
  Analytics({AnalyticsTransport? transport})
    : _transport = transport ?? createTransport();

  /// The app-wide instance. Until [init] runs (or when no id is configured)
  /// it ignores everything.
  static Analytics instance = Analytics._off();

  Analytics._off() : _transport = _NoTransport();

  static const consentKey = 'analytics_enabled';
  static final _idPattern = RegExp(r'^G-[A-Z0-9]{6,}$');

  final AnalyticsTransport _transport;
  bool _configured = false;
  bool _enabled = true;

  /// An id is set, so a choice is worth showing.
  bool get configured => _configured;

  /// Usage is being reported. False when switched off or not configured.
  bool get enabled => _configured && _enabled;

  /// Reads `.env` and the saved choice, then starts the transport. Safe to call
  /// when nothing is configured; it then does nothing.
  Future<void> init({
    Map<String, String>? env,
    SharedPreferences? prefs,
  }) async {
    final e = env ?? dotenv.env;
    final id = (e['GA_MEASUREMENT_ID'] ?? '').trim();
    if (!_idPattern.hasMatch(id)) return;
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      _enabled = p.getBool(consentKey) ?? true;
    } catch (_) {
      _enabled = true;
    }
    await _transport.start(
      measurementId: id,
      apiSecret: (e['GA_API_SECRET'] ?? '').trim(),
      granted: _enabled,
    );
    _configured = true;
    notifyListeners();
  }

  /// The "share usage data" switch.
  Future<void> setEnabled(bool value, {SharedPreferences? prefs}) async {
    _enabled = value;
    _transport.setConsent(value);
    notifyListeners();
    try {
      final p = prefs ?? await SharedPreferences.getInstance();
      await p.setBool(consentKey, value);
    } catch (_) {}
  }

  /// A screen came into view. [name] is a stable id such as `product`, not a
  /// class name (web builds rename classes).
  void screen(String name) =>
      event('screen_view', {'screen_name': name, 'screen_class': name});

  void event(String name, [Map<String, Object?> params = const {}]) {
    if (!enabled) return;
    try {
      _transport.send(AnalyticsEvent(name, clean(params)));
    } catch (_) {
      // Reporting must never break the app.
    }
  }

  // --- Shopping steps, with GA4's standard names so its reports light up. ---

  void viewItem({
    required String id,
    required String name,
    required num price,
    String? category,
  }) => event('view_item', {
    'currency': currency,
    'value': price,
    'items': [_item(id: id, name: name, price: price, category: category)],
  });

  void addToCart({
    required String id,
    required String name,
    required num price,
    int quantity = 1,
    String? variant,
    String? category,
  }) => event('add_to_cart', {
    'currency': currency,
    'value': price * quantity,
    'items': [
      _item(
        id: id,
        name: name,
        price: price,
        quantity: quantity,
        variant: variant,
        category: category,
      ),
    ],
  });

  void beginCheckout({required num value, required int itemCount}) => event(
    'begin_checkout',
    {'currency': currency, 'value': value, 'item_count': itemCount},
  );

  void purchase({
    required String orderId,
    required num value,
    required String paymentMethod,
    List<Map<String, Object?>> items = const [],
  }) => event('purchase', {
    'transaction_id': orderId,
    'currency': currency,
    'value': value,
    'payment_type': paymentMethod,
    if (items.isNotEmpty) 'items': items,
  });

  void search(String term) => event('search', {'search_term': term});

  /// Indian rupees: the shop's only currency.
  static const currency = 'INR';

  static Map<String, Object?> item({
    required String id,
    required String name,
    required num price,
    int quantity = 1,
    String? variant,
    String? category,
  }) => _item(
    id: id,
    name: name,
    price: price,
    quantity: quantity,
    variant: variant,
    category: category,
  );

  static Map<String, Object?> _item({
    required String id,
    required String name,
    required num price,
    int quantity = 1,
    String? variant,
    String? category,
  }) => {
    'item_id': id,
    'item_name': name,
    'price': price,
    'quantity': quantity,
    'item_variant': ?variant,
    'item_category': ?category,
  };

  /// GA4's limits: 25 parameters, text up to 100 characters, no empty values.
  /// Lists of items are cleaned the same way.
  @visibleForTesting
  static Map<String, Object> clean(Map<String, Object?> params) {
    Object? tidy(Object? v) {
      if (v is String) return v.length > 100 ? v.substring(0, 100) : v;
      if (v is num || v is bool) return v;
      if (v is List) {
        final list = [for (final x in v.take(200)) ?tidy(x)];
        return list.isEmpty ? null : list;
      }
      if (v is Map) {
        final map = <String, Object>{};
        for (final en in v.entries.take(25)) {
          final t = tidy(en.value);
          if (t != null) map['${en.key}'] = t;
        }
        return map.isEmpty ? null : map;
      }
      return null;
    }

    final out = <String, Object>{};
    for (final en in params.entries) {
      if (out.length >= 25) break;
      final t = tidy(en.value);
      if (t != null) out[en.key] = t;
    }
    return out;
  }
}

class _NoTransport implements AnalyticsTransport {
  @override
  Future<void> start({
    required String measurementId,
    String? apiSecret,
    required bool granted,
  }) async {}

  @override
  void send(AnalyticsEvent event) {}

  @override
  void setConsent(bool granted) {}
}
