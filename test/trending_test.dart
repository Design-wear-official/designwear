import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/widgets/agent_chat_widget.dart';
import 'package:designwear/services/ai/ai_agent_service.dart';
import 'package:designwear/services/ai/ai_service.dart';
import 'package:designwear/services/ai/remote_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A stand-in assistant that records whether trends were asked for, and answers from "a web search".
class _TrendAgent extends UnconfiguredAiService {
  _TrendAgent({this.trendsOn = true});
  final bool trendsOn;
  final asked = <({String message, bool trends})>[];

  @override
  bool get agentEnabled => true;
  @override
  bool get tryOnEnabled => false;
  @override
  bool get trendsEnabled => trendsOn;

  @override
  Future<DesignAgentReply> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
    bool trends = false,
  }) async {
    asked.add((message: message, trends: trends));
    return DesignAgentReply(
      text: 'Sunset gradients are big right now.',
      trends: trends
          ? const TrendsInfo(
              asOf: '2026-11-08',
              sources: [
                (title: 'Example', url: 'https://www.example.com/trends'),
              ],
            )
          : null,
    );
  }
}

Widget _chat() => MaterialApp(
  home: Scaffold(
    body: Stack(
      children: [
        AgentChatWidget(currentDesign: CustomDesign(), onDesignUpdate: (_) {}),
      ],
    ),
  ),
);

void main() {
  late AiService original;
  setUp(() => original = AiService.instance);
  tearDown(() => AiService.instance = original);

  group('the server flag', () {
    test('config says whether the assistant can use trends', () async {
      final on = ApiClient(
        'https://api.example.com',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'designAgent': true, 'trends': true}),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      expect((await on.features()).trends, isTrue);
      final off = ApiClient(
        'https://api.example.com',
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'designAgent': true}),
            200,
            headers: {'content-type': 'application/json'},
          ),
        ),
      );
      expect((await off.features()).trends, isFalse);
    });
  });

  group('RemoteAiService', () {
    test(
      'asks for trends only when told to, and keeps only https sources',
      () async {
        final bodies = <Map<String, Object?>>[];
        final api = ApiClient(
          'https://api.example.com',
          httpClient: MockClient((request) async {
            bodies.add(jsonDecode(request.body) as Map<String, Object?>);
            return http.Response(
              jsonEncode({
                'text': 'Pastels are in.',
                'design': null,
                'trends': {
                  'asOf': '2026-11-08',
                  'sources': [
                    {'title': 'Good', 'url': 'https://good.example/a'},
                    {'title': 'Bad', 'url': 'http://insecure.example/b'},
                    {'title': 'Script', 'url': 'javascript:alert(1)'},
                  ],
                },
              }),
              200,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
        final ai = RemoteAiService(
          api,
          const ServerFeatures(designAgent: true, trends: true),
        );
        expect(ai.trendsEnabled, isTrue);

        final plain = await ai.designAgent(
          message: 'a tee',
          design: {},
          history: const [],
        );
        expect(
          bodies.last.containsKey('trends'),
          isFalse,
          reason: 'not asked for, not sent',
        );
        expect(
          plain.trends,
          isNotNull,
          reason: 'but the server may add it when the message asks',
        );

        final asked = await ai.designAgent(
          message: 'trending?',
          design: {},
          history: const [],
          trends: true,
        );
        expect(bodies.last['trends'], isTrue);
        expect(asked.trends!.asOf, '2026-11-08');
        expect(asked.trends!.sources.map((s) => s.url), [
          'https://good.example/a',
        ]);
      },
    );

    test('trends need both the flag and the assistant', () {
      expect(
        RemoteAiService(
          ApiClient('https://a.example.com'),
          const ServerFeatures(trends: true),
        ).trendsEnabled,
        isFalse,
      );
      expect(
        RemoteAiService(
          ApiClient('https://a.example.com'),
          const ServerFeatures(designAgent: true),
        ).trendsEnabled,
        isFalse,
      );
    });
  });

  group('the chat', () {
    test(
      'the assistant service passes the request and the answer through',
      () async {
        final fake = _TrendAgent();
        AiService.instance = fake;
        final r = await AIAgentService().sendMessage(
          "What's trending",
          CustomDesign(),
          trends: true,
        );
        expect(fake.asked.single.trends, isTrue);
        expect(r.trends!.asOf, '2026-11-08');
      },
    );

    testWidgets(
      "a What's trending chip asks, and the answer shows where it came from",
      (tester) async {
        tester.view.physicalSize = const Size(1000, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final fake = _TrendAgent();
        AiService.instance = fake;
        await tester.pumpWidget(_chat());
        await tester.tap(find.byIcon(Icons.auto_awesome));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('trending-chip')), findsOneWidget);
        await tester.tap(find.byKey(const Key('trending-chip')));
        await tester.pumpAndSettle(); // lets the list scroll down to the answer

        expect(fake.asked.single.trends, isTrue);
        expect(fake.asked.single.message, contains('trending'));
        expect(find.byKey(const Key('trends-sources')), findsOneWidget);
        expect(find.text('From a web search on 2026-11-08'), findsOneWidget);
        expect(
          find.text('example.com'),
          findsOneWidget,
          reason: 'the page, shown by its site',
        );
        await tester.pump(const Duration(seconds: 5));
      },
    );

    testWidgets('no chip when the server has trends switched off', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AiService.instance = _TrendAgent(trendsOn: false);
      await tester.pumpWidget(_chat());
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('trending-chip')), findsNothing);
    });
  });
}
