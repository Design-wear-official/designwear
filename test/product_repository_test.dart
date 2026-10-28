import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/cms/cms_config.dart';
import 'package:designwear/cms/cms_service.dart';
import 'package:designwear/data/product_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

http.Response _json(int status, Object body) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

const _records = [
  {
    'id': 'a',
    'title': 'T-shirt',
    'price': 10,
    'stockCount': 5,
    'featured': true,
  },
  {'id': 'r', 'title': 'Remix by @user', 'price': 499},
  {'id': 'z', 'title': 'Free thing', 'price': 0},
];

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  ApiClient api(Future<http.Response> Function(http.Request) h) =>
      ApiClient('https://api.example.com', httpClient: MockClient(h));
  CmsService cms(List<http.Request> seen) => CmsService(
    const CmsConfig(
      baseUrl: 'https://cms.example.com',
      connectionId: 'c',
      viewerToken: 't',
    ),
    httpClient: MockClient((r) async {
      seen.add(r);
      return _json(200, {
        'data': _records,
        'nextCursor': null,
        'limit': 40,
        'notes': [],
      });
    }),
  );

  test('uses the API and never touches the CMS when the API answers', () async {
    final cmsCalls = <http.Request>[];
    late http.Request seen;
    final repo = ProductRepository(
      api: api((r) async {
        seen = r;
        return _json(200, {'data': _records});
      }),
      cms: cms(cmsCalls),
    );
    final items = await repo.list(limit: 12);
    expect(items.map((p) => p.id), [
      'a',
    ], reason: 'remixes and unpriced entries are dropped');
    expect(seen.url.path, '/v1/products');
    expect(seen.url.queryParameters['limit'], '12');
    expect(cmsCalls, isEmpty);
  });

  test('falls back to the CMS when the API is unreachable', () async {
    final cmsCalls = <http.Request>[];
    final repo = ProductRepository(
      api: api((_) async => throw http.ClientException('offline')),
      cms: cms(cmsCalls),
    );
    expect((await repo.list()).map((p) => p.id), ['a']);
    expect(cmsCalls, hasLength(1));
  });

  test('without a CMS, an API failure is reported, not hidden', () async {
    final repo = ProductRepository(
      api: api(
        (_) async => _json(500, {
          'error': {'code': 'internal', 'message': 'x'},
        }),
      ),
    );
    await expectLater(repo.list(), throwsA(isA<ApiException>()));
  });

  test(
    'works from the CMS alone, and resolve() is null when nothing is set up',
    () async {
      expect(ProductRepository.resolve(), isNull);
      final repo = ProductRepository(cms: cms([]));
      expect((await repo.list()).single.title, 'T-shirt');
    },
  );

  test('featured and single-product reads go through the API', () async {
    final paths = <String>[];
    final repo = ProductRepository(
      api: api((r) async {
        paths.add('${r.url.path}?${r.url.query}');
        return _json(
          200,
          r.url.path == '/v1/products/a'
              ? {'data': _records[0]}
              : {
                  'data': [_records[0]],
                },
        );
      }),
    );
    expect((await repo.featured()).single.id, 'a');
    expect((await repo.get('a')).title, 'T-shirt');
    expect(paths.first, contains('featured=1'));
    expect(paths.last, startsWith('/v1/products/a'));
  });
}
