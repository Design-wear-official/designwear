import 'dart:convert';

import 'package:designwear/models/product.dart';
import 'package:designwear/services/analytics/analytics.dart';
import 'package:designwear/services/analytics/analytics_transport.dart';
import 'package:designwear/services/shop/cart_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Recorder implements AnalyticsTransport {
  final events = <AnalyticsEvent>[];
  String? startedWith;
  String? secret;
  bool? granted;

  @override
  Future<void> start({
    required String measurementId,
    String? apiSecret,
    required bool granted,
  }) async {
    startedWith = measurementId;
    secret = apiSecret;
    this.granted = granted;
  }

  @override
  void setConsent(bool granted) => this.granted = granted;

  @override
  void send(AnalyticsEvent event) => events.add(event);
}

const _id = 'G-Q71RGCNCR1';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(() => Analytics.instance = Analytics());

  group('configuration', () {
    test('does nothing without a measurement id', () async {
      final t = _Recorder();
      final a = Analytics(transport: t);
      await a.init(env: {}, prefs: await SharedPreferences.getInstance());
      a.screen('home');
      expect(a.configured, isFalse);
      expect(t.startedWith, isNull);
      expect(t.events, isEmpty);
    });

    test('ignores an id that is not a GA4 measurement id', () async {
      final t = _Recorder();
      final a = Analytics(transport: t);
      await a.init(
        env: {'GA_MEASUREMENT_ID': 'UA-123456-1'},
        prefs: await SharedPreferences.getInstance(),
      );
      expect(a.configured, isFalse);
      expect(t.startedWith, isNull);
    });

    test('starts with the id and the API secret', () async {
      final t = _Recorder();
      final a = Analytics(transport: t);
      await a.init(
        env: {'GA_MEASUREMENT_ID': ' $_id ', 'GA_API_SECRET': 'shh'},
        prefs: await SharedPreferences.getInstance(),
      );
      expect(a.configured, isTrue);
      expect(a.enabled, isTrue);
      expect(t.startedWith, _id);
      expect(t.secret, 'shh');
      expect(t.granted, isTrue);
    });
  });

  group('consent', () {
    test('switching off stops events and is remembered', () async {
      final prefs = await SharedPreferences.getInstance();
      final t = _Recorder();
      final a = Analytics(transport: t);
      await a.init(env: {'GA_MEASUREMENT_ID': _id}, prefs: prefs);
      a.screen('home');
      expect(t.events, hasLength(1));

      await a.setEnabled(false, prefs: prefs);
      a.screen('cart');
      expect(t.events, hasLength(1));
      expect(t.granted, isFalse);
      expect(prefs.getBool(Analytics.consentKey), isFalse);

      // A new start (the next time the app opens) keeps the choice.
      final t2 = _Recorder();
      final b = Analytics(transport: t2);
      await b.init(env: {'GA_MEASUREMENT_ID': _id}, prefs: prefs);
      expect(b.enabled, isFalse);
      expect(t2.granted, isFalse);
      b.screen('home');
      expect(t2.events, isEmpty);
    });
  });

  group('events', () {
    late _Recorder t;
    late Analytics a;
    setUp(() async {
      t = _Recorder();
      a = Analytics(transport: t);
      await a.init(
        env: {'GA_MEASUREMENT_ID': _id},
        prefs: await SharedPreferences.getInstance(),
      );
    });

    test('screen_view carries the screen name', () {
      a.screen('product');
      expect(t.events.single.name, 'screen_view');
      expect(t.events.single.params['screen_name'], 'product');
    });

    test('purchase uses GA4 names and no personal details', () {
      a.purchase(
        orderId: 'o-1',
        value: 2499,
        paymentMethod: 'cod',
        items: [
          Analytics.item(
            id: 'w1',
            name: 'Meridian 40',
            price: 2499,
            variant: 'Black leather',
          ),
        ],
      );
      final e = t.events.single;
      expect(e.name, 'purchase');
      expect(e.params['transaction_id'], 'o-1');
      expect(e.params['currency'], 'INR');
      expect(e.params['value'], 2499);
      final items = e.params['items'] as List;
      expect((items.single as Map)['item_variant'], 'Black leather');
      final text = jsonEncode(e.params).toLowerCase();
      for (final pii in ['email', 'phone', 'address']) {
        expect(text.contains(pii), isFalse, reason: pii);
      }
    });

    test('adding to the cart reports the product', () {
      Analytics.instance = a;
      final cart = CartService();
      final p = Product.fromRecord({
        'id': 'w1',
        'title': 'Meridian 40',
        'price': 2499,
        'stockCount': 3,
        'productType': 'watch',
        'variantLabel': 'Strap',
        'variants': ['Black leather'],
      });
      cart.addToCart(p, size: 'Black leather');
      expect(cart.lines.single.productId, 'w1');
      final e = t.events.single;
      expect(e.name, 'add_to_cart');
      expect(e.params['value'], 2499);
      final item = (e.params['items'] as List).single as Map;
      expect(item['item_category'], 'watch');
      expect(item['item_variant'], 'Black leather');
    });
  });

  group('clean', () {
    test('drops empty values, shortens text, keeps at most 25 keys', () {
      final out = Analytics.clean({
        'a': null,
        'b': 'x' * 300,
        'c': 5,
        'd': <Object?>[],
        'e': <String, Object?>{'k': null},
        for (var i = 0; i < 40; i++) 'k$i': i,
      });
      expect(out.containsKey('a'), isFalse);
      expect(out.containsKey('d'), isFalse);
      expect(out.containsKey('e'), isFalse);
      expect((out['b'] as String).length, 100);
      expect(out['c'], 5);
      expect(out.length, 25);
    });
  });

  group('Measurement Protocol (Android, iOS, desktop)', () {
    Future<(HttpAnalyticsTransport, List<http.Request>)> start({
      String? secret = 'shh',
      bool granted = true,
    }) async {
      final seen = <http.Request>[];
      final t = HttpAnalyticsTransport(
        client: MockClient((r) async {
          seen.add(r);
          return http.Response('', 204);
        }),
      );
      await t.start(measurementId: _id, apiSecret: secret, granted: granted);
      return (t, seen);
    }

    test(
      'posts the event with the id, secret and an anonymous client id',
      () async {
        final (t, seen) = await start();
        t.send(const AnalyticsEvent('screen_view', {'screen_name': 'home'}));
        await Future<void>.delayed(Duration.zero);
        expect(seen, hasLength(1));
        final r = seen.single;
        expect(r.method, 'POST');
        expect(r.url.host, 'www.google-analytics.com');
        expect(r.url.path, '/mp/collect');
        expect(r.url.queryParameters['measurement_id'], _id);
        expect(r.url.queryParameters['api_secret'], 'shh');
        final body = jsonDecode(r.body) as Map;
        expect(body['client_id'], isNotEmpty);
        final event = (body['events'] as List).single as Map;
        expect(event['name'], 'screen_view');
        expect((event['params'] as Map)['screen_name'], 'home');
        expect((event['params'] as Map)['session_id'], isA<int>());
      },
    );

    test('keeps the same client id between starts', () async {
      final (a, seenA) = await start();
      a.send(const AnalyticsEvent('x'));
      final (b, seenB) = await start();
      b.send(const AnalyticsEvent('x'));
      await Future<void>.delayed(Duration.zero);
      expect(
        (jsonDecode(seenA.single.body) as Map)['client_id'],
        (jsonDecode(seenB.single.body) as Map)['client_id'],
      );
    });

    test('sends nothing without an API secret or when switched off', () async {
      final (noSecret, seen1) = await start(secret: null);
      noSecret.send(const AnalyticsEvent('x'));
      final (off, seen2) = await start(granted: false);
      off.send(const AnalyticsEvent('x'));
      await Future<void>.delayed(Duration.zero);
      expect(seen1, isEmpty);
      expect(seen2, isEmpty);
    });

    test('a failing request never throws', () async {
      final t = HttpAnalyticsTransport(
        client: MockClient((_) async => throw Exception('offline')),
      );
      await t.start(measurementId: _id, apiSecret: 's', granted: true);
      t.send(const AnalyticsEvent('x'));
      await Future<void>.delayed(Duration.zero);
    });
  });
}
