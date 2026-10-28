import 'dart:convert';
import 'dart:math';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/commerce.dart';
import 'package:designwear/services/auth/auth_service.dart';
import 'package:designwear/services/shop/cart_service.dart';
import 'package:designwear/services/community/community_service.dart';
import 'package:designwear/services/ai/remote_ai_service.dart';
import 'package:designwear/services/ai/ai_service.dart';
import 'package:designwear/services/shop/stores.dart';
import 'package:designwear/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

ApiClient _client(Future<http.Response> Function(http.Request) handler) =>
    ApiClient('https://api.example.com', httpClient: MockClient(handler));

/// WCAG contrast ratio between two colours.
double _contrast(Color a, Color b) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
  double lum(Color c) =>
      0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
  final la = lum(a), lb = lum(b);
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('ApiClient', () {
    test('requires https except for localhost', () {
      expect(() => ApiClient('http://api.example.com'), throwsArgumentError);
      expect(() => ApiClient('http://localhost:8787'), returnsNormally);
      expect(() => ApiClient('https://api.example.com/'), returnsNormally);
    });

    test('sends the bearer token and maps server errors', () async {
      late http.Request seen;
      final api = _client((r) async {
        seen = r;
        return r.url.path == '/v1/bad'
            ? _json(400, {
                'error': {'code': 'invalid_size', 'message': 'Pick a size.'},
              })
            : _json(200, {'ok': true});
      });
      await api.setToken('tok');
      await api.get('/v1/me');
      expect(seen.headers['authorization'], 'Bearer tok');
      await expectLater(
        api.get('/v1/bad'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Pick a size.',
          ),
        ),
      );
    });

    test('a 401 clears the session and notifies', () async {
      final api = _client(
        (_) async => _json(401, {
          'error': {'code': 'unauthenticated', 'message': 'x'},
        }),
      );
      await api.setToken('stale');
      var expired = false;
      api.onSessionExpired = () => expired = true;
      await expectLater(api.get('/v1/me'), throwsA(isA<ApiException>()));
      expect(api.hasToken, isFalse);
      expect(expired, isTrue);
    });

    test('network failures become a friendly error', () async {
      final api = _client((_) async => throw http.ClientException('boom'));
      await expectLater(
        api.get('/v1/me'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'network')),
      );
    });
  });

  group('server-backed services', () {
    test(
      'sign in stores the token; wrong password returns the server message',
      () async {
        final api = _client((r) async {
          final body = jsonDecode(r.body) as Map;
          if (r.url.path == '/v1/auth/login') {
            return body['password'] == 'goodpassword'
                ? _json(200, {
                    'token': 't1',
                    'user': {'id': 'u', 'name': 'Asha', 'email': 'a@x.com'},
                  })
                : _json(401, {
                    'error': {
                      'code': 'invalid_credentials',
                      'message': 'Incorrect email or password.',
                    },
                  });
          }
          return _json(404, {});
        });
        final auth = AuthService(api: api);
        expect(
          await auth.signIn('a@x.com', 'nope'),
          'Incorrect email or password.',
        );
        expect(auth.isSignedIn, isFalse);
        expect(await auth.signIn('a@x.com', 'goodpassword'), isNull);
        expect(auth.user!.name, 'Asha');
        expect(api.hasToken, isTrue);
        await auth.signOut();
        expect(api.hasToken, isFalse);
      },
    );

    test(
      'orders are priced by the server and the client sends no prices',
      () async {
        late Map sent;
        final api = _client((r) async {
          sent = jsonDecode(r.body) as Map;
          return _json(201, {
            'order': {
              'id': 'DW1',
              'createdAt': '2026-01-01T00:00:00Z',
              'status': 'placed',
              'subtotal': 1000,
              'tax': 180,
              'total': 1180,
              'lines': [
                {
                  'productId': 'p1',
                  'title': 'Tee',
                  'unitPrice': 500,
                  'size': 'M',
                  'quantity': 2,
                },
              ],
              'address': {
                'label': 'Home',
                'name': 'A',
                'phone': '1',
                'line1': 'x',
                'city': 'c',
                'state': 's',
                'pin': '411001',
              },
            },
          });
        });
        final orders = OrderStore(api: api);
        final order = await orders.place(
          lines: [
            CartLine(
              productId: 'p1',
              title: 'Tee',
              unitPrice: 1,
              size: 'M',
              quantity: 2,
            ),
          ],
          address: const Address(
            id: 'a',
            label: 'Home',
            name: 'A',
            phone: '1',
            line1: 'x',
            city: 'c',
            state: 's',
            pin: '411001',
          ),
        );
        expect(order.total, 1180);
        expect(orders.items.single.id, 'DW1');
        final line = (sent['lines'] as List).single as Map;
        expect(line.containsKey('unitPrice'), isFalse);
        expect(line['quantity'], 2);
      },
    );

    test(
      'cart mirrors to the server when signed in and merges on sign-in',
      () async {
        final puts = <Map>[];
        final api = _client((r) async {
          if (r.method == 'PUT') {
            puts.add(jsonDecode(r.body) as Map);
            return _json(200, {'lines': []});
          }
          return _json(200, {
            'lines': [
              {
                'productId': 'srv',
                'title': 'Server item',
                'unitPrice': 10,
                'size': 'S',
                'quantity': 1,
              },
            ],
          });
        });
        await api.setToken('t');
        final cart = CartService(api: api)
          ..add(
            CartLine(productId: 'local', title: 'L', unitPrice: 5, size: 'M'),
          );
        // Changes are debounced (600 ms) so rapid taps become one request.
        cart.add(
          CartLine(productId: 'local', title: 'L', unitPrice: 5, size: 'M'),
        );
        expect(puts, isEmpty);
        await Future<void>.delayed(const Duration(milliseconds: 800));
        expect(puts, hasLength(1));
        await cart.syncFromServer();
        expect(
          cart.lines.map((l) => l.productId),
          containsAll(['local', 'srv']),
        );
      },
    );

    test('community: publishes the studio design, previews and remix link only once', () async {
      final bodies = <Map>[];
      final api = _client((r) async {
        if (r.method == 'POST') bodies.add(jsonDecode(r.body) as Map);
        return _json(200, {
          'design': {
            'id': 'srv1',
            'name': 'Remix',
            'garment': 'T-Shirt',
            'published': true,
            'creatorName': 'Bo',
            'creatorHandle': 'bo',
            'likeCount': 2,
            'remixCount': 0,
            'liked': true,
            'mine': true,
            'price': 499,
            'designJson': {'baseColor': '0xFF000000', 'elements': []},
            'previewImage': 'AAAA',
            'remixedFrom': {'id': 'p', 'name': 'Sunrise', 'handle': 'asha'},
            'lineage': [
              {'handle': 'asha'},
            ],
          },
        });
      });
      final service = CommunityService(api);
      final saved = await service.publishStudio(
        name: 'Remix',
        garment: 'tshirt',
        designJson: {'elements': []},
        remixOfId: 'parent',
        previewImage: 'AAAA',
      );
      expect(saved.lineage, ['asha']);
      expect(saved.remixedFromName, 'Sunrise');
      expect(saved.previewImage, 'AAAA');
      expect(saved.toStudioDesign()!.baseColor, '0xFF000000');
      expect(saved.toStudioDesign()!.name, 'Remix remix');
      await service.publishStudio(
        name: 'Remix',
        garment: 'tshirt',
        designJson: {'elements': []},
        serverId: 'srv1',
        remixOfId: 'parent',
      );
      expect(bodies[0]['remixOf'], 'parent');
      expect(bodies[0]['designJson'], isA<Map>());
      expect(
        bodies[1].containsKey('remixOf'),
        isFalse,
        reason: 'only the first upload links the parent',
      );
      expect(bodies[1]['id'], 'srv1');
      expect(bodies[1].containsKey('previewImage'), isFalse);
    });

    test('AI: remote chat/try-on map server states', () async {
      final api = _client((r) async {
        if (r.url.path == '/v1/ai/chat') {
          return _json(200, {'reply': 'Try navy.'});
        }
        return _json(503, {
          'error': {'code': 'ai_unavailable', 'message': 'off'},
        });
      });
      final ai = RemoteAiService(api, const ServerFeatures(chat: true));
      expect(await ai.chat([(fromUser: true, text: 'hi')]), 'Try navy.');
      await expectLater(
        ai.tryOn(personPhoto: [1], productId: 'p'),
        throwsA(isA<AiUnavailable>()),
      );
      expect(ai.chatEnabled, isTrue);
      expect(ai.tryOnEnabled, isFalse);
    });
  });

  group('themes', () {
    for (final brightness in Brightness.values) {
      test('${brightness.name}: text and accents are readable', () {
        final t = buildAppTheme(brightness);
        final bg = t.scaffoldBackgroundColor;
        expect(_contrast(t.colorScheme.onSurface, bg), greaterThan(7));
        expect(
          _contrast(t.colorScheme.onPrimary, t.colorScheme.primary),
          greaterThan(4.5),
          reason: 'primary label',
        );
        final accent = brightness == Brightness.dark
            ? AppColors.marigold
            : const Color(0xFF9A5B00);
        expect(
          _contrast(accent, bg),
          greaterThan(4.5),
          reason: 'prices and links',
        );
        expect(
          _contrast(AppColors.marigoldInk, AppColors.marigold),
          greaterThan(4.5),
          reason: 'filled button label',
        );
        expect(
          _contrast(t.colorScheme.onSurfaceVariant, bg),
          greaterThan(4.5),
          reason: 'secondary text',
        );
      });
    }
  });
}
