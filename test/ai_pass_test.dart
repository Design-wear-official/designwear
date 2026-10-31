import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/services/ai/remote_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test(
    'the graphic for a design edit carries the pass once, then not again',
    () async {
      final sent = <String, Map<String, Object?>>{};
      var agentCalls = 0;
      final api = ApiClient(
        'https://api.example.com',
        httpClient: MockClient((request) async {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          sent['${++agentCalls} ${request.url.path}'] = body;
          final json = request.url.path.endsWith('design-agent')
              ? {
                  'text': 'Done',
                  'design': {'elements': []},
                  'imagePass': 'pass-1',
                }
              : {
                  'image': base64Encode([1, 2, 3]),
                };
          return http.Response(
            jsonEncode(json),
            200,
            headers: {'content-type': 'application/json'},
          );
        }),
      );
      final ai = RemoteAiService(
        api,
        const ServerFeatures(designAgent: true, tryOn: true),
      );

      await ai.designAgent(message: 'a sun tee', design: {}, history: const []);
      await ai.designImage('sun');
      await ai.designImage('sun again');

      expect(sent['2 /v1/ai/design-image']!['pass'], 'pass-1');
      expect(sent['3 /v1/ai/design-image']!.containsKey('pass'), isFalse);
    },
  );
}
