import 'dart:convert';

import 'package:designwear/cms/cms_config.dart';
import 'package:designwear/cms/cms_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('unconfigured when any value is empty', () {
    const c = CmsConfig(
      baseUrl: 'https://x',
      connectionId: '',
      viewerToken: 't',
    );
    expect(c.isConfigured, isFalse);
  });

  test('sends bearer viewer token to the connection and collection', () async {
    late http.Request seen;
    final mock = MockClient((req) async {
      seen = req;
      return http.Response(
        jsonEncode({'data': [], 'nextCursor': null}),
        200,
        headers: {'content-type': 'application/json'},
      );
    });
    final cms = CmsService(
      const CmsConfig(
        baseUrl: 'https://cms.example.com',
        connectionId: 'conn_1',
        viewerToken: 'viewer-token',
      ),
      httpClient: mock,
    );

    await cms.collection('products').query().limit(5).list();

    expect(seen.headers['authorization'], 'Bearer viewer-token');
    expect(
      seen.url.path,
      '/v1/connections/conn_1/collections/products/records',
    );
    expect(seen.url.queryParameters['limit'], '5');
  });
}
