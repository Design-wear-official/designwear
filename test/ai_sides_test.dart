import 'package:flutter/painting.dart';

import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/screens/studio/editor/support/design_studio_utils.dart';
import 'package:designwear/services/ai/ai_agent_service.dart';
import 'package:designwear/services/ai/ai_service.dart';
import 'package:designwear/services/ai/remote_ai_service.dart';
import 'package:designwear/presentation/widgets/agent_chat_widget.dart';
import 'package:flutter/material.dart' show Icons, MaterialApp, Scaffold, Stack, TextField, ValueKey, Size;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A stand-in assistant: it edits the design (a text line) and "draws" the faces it is told to.
class _SidesAgent extends UnconfiguredAiService {
  _SidesAgent({this.failed = const [], this.art, this.pictureOnly = false});
  final bool pictureOnly;
  final String? art;
  final prompts = <String>[];
  final List<String> failed;
  final references = <List<List<int>>>[];

  @override
  bool get agentEnabled => true;
  @override
  bool get tryOnEnabled => true;

  @override
  Future<DesignAgentReply> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
    bool trends = false,
  }) async => DesignAgentReply(
    text: 'Here is your design.',
    art: art,
    design: pictureOnly ? null : <String, Object?>{
      'baseColor': '0xFF000000',
      'elements': [
        {
          'id': 't1',
          'type': 'text',
          'content': 'DOOMSDAY',
          'x': 0,
          'y': 90,
          'size': 40,
          'color': '0xFFFFFFFF',
        },
      ],
    },
  );

  @override
  Future<DesignSides> designSides(
    String prompt, {
    List<List<int>> images = const [],
  }) async {
    references.add(images);
    prompts.add(prompt);
    return DesignSides(
      images: {
        for (final s in ['front', 'back', 'left', 'right'])
          if (!failed.contains(s)) s: _png,
      },
      failed: failed,
    );
  }
}

// A 1x1 transparent PNG.
const _png =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late AiService original;
  setUp(() => original = AiService.instance);
  tearDown(() => AiService.instance = original);

  group('a design fills every view', () {
    test('the front, back and both sleeves each get a picture, underneath the assistant\'s text', () async {
      AiService.instance = _SidesAgent();
      final r = await AIAgentService().sendMessage(
        'green doomsday storm',
        CustomDesign(),
      );
      final els = r.updatedDesign!.elements;
      expect(els.length, 5);
      final images = els
          .where((e) => e.type == DesignElementType.image)
          .toList();
      expect(images.map((e) => e.side).toSet(), {
        DesignSide.front,
        DesignSide.back,
        DesignSide.left,
        DesignSide.right,
      });
      expect(
        els.last.type,
        DesignElementType.text,
        reason: 'the text is drawn on top of the pictures',
      );
      for (final e in images) {
        expect(e.content, isNotEmpty);
        expect(
          e.width,
          e.side.isSleeve ? 90 : 200,
          reason: 'a small emblem on a sleeve, a large picture on the body',
        );
      }
      expect(
        r.updatedDesign!.elementsForSide(DesignSide.left).single.type,
        DesignElementType.image,
      );
      expect(
        r.updatedDesign!.elementsForSide(DesignSide.front).length,
        2,
        reason: 'picture and text on the front',
      );
    });

    test('a face that could not be drawn is said so plainly, and the rest still arrive', () async {
      AiService.instance = _SidesAgent(failed: ['back']);
      final r = await AIAgentService().sendMessage('storm', CustomDesign());
      expect(r.text, contains("couldn't draw the back"));
      expect(r.updatedDesign!.elementsForSide(DesignSide.back), isEmpty);
      expect(
        r.updatedDesign!
            .elementsForSide(DesignSide.front)
            .any((e) => e.type == DesignElementType.image),
        isTrue,
      );
    });

    test('the faces are drawn from the assistant\'s art brief, not the customer\'s message', () async {
      final fake = _SidesAgent(art: 'a green storm cloud over a dark city');
      AiService.instance = fake;
      await AIAgentService().sendMessage('make it better', CustomDesign());
      expect(fake.prompts.single, 'a green storm cloud over a dark city');
    });

    test('a picture-only reply adds the pictures to the current design and keeps what is there', () async {
      final fake = _SidesAgent(art: 'a dragon', pictureOnly: true);
      AiService.instance = fake;
      final current = CustomDesign(
        elements: [
          DesignElement(
            id: 'mine',
            type: DesignElementType.text,
            content: 'KEEP',
            x: 0,
            y: 0,
          ),
        ],
      );
      final r = await AIAgentService().sendMessage('generate a dragon', current);
      expect(fake.prompts.single, 'a dragon');
      final els = r.updatedDesign!.elements;
      expect(els.length, 5);
      expect(els.last.content, 'KEEP');
      expect(
        els.where((e) => e.type == DesignElementType.image).length,
        4,
      );
      expect(r.previewBase64, _png);
    });

    test('a reply with neither a design nor a brief draws nothing', () async {
      final fake = _SidesAgent(pictureOnly: true);
      AiService.instance = fake;
      final r = await AIAgentService().sendMessage('hi', CustomDesign());
      expect(r.updatedDesign, isNull);
      expect(r.previewBase64, isNull);
      expect(fake.prompts, isEmpty);
    });

    testWidgets('the picture shows as a thumbnail in the chat bubble', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      AiService.instance = _SidesAgent(art: 'a dragon', pictureOnly: true);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                AgentChatWidget(
                  currentDesign: CustomDesign(),
                  onDesignUpdate: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byIcon(Icons.auto_awesome));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'generate a dragon');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('agent-preview')), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    test('without a brief the customer\'s message is the fallback', () async {
      final fake = _SidesAgent();
      AiService.instance = fake;
      await AIAgentService().sendMessage('green storm', CustomDesign());
      expect(fake.prompts.single, 'green storm');
    });

    test('the customer\'s own pictures are sent as references', () async {
      final fake = _SidesAgent();
      AiService.instance = fake;
      final layers = await AIAgentService().generateSideLayers(
        'my logo',
        references: [
          [9, 9],
          [8],
        ],
      );
      expect(fake.references.single, [
        [9, 9],
        [8],
      ]);
      expect(layers.layers.length, 4);
    });

    test('when nothing can be drawn the text design still arrives', () async {
      AiService.instance = _SidesAgent(
        failed: ['front', 'back', 'left', 'right'],
      );
      final r = await AIAgentService().sendMessage('storm', CustomDesign());
      expect(r.updatedDesign!.elements.single.type, DesignElementType.text);
    });
  });

  group('RemoteAiService.designSides', () {
    test('sends the prompt, the pass from the design edit (once) and the customer pictures, and reads the faces', () async {
      final sent = <Map<String, Object?>>[];
      final api = ApiClient(
        'https://api.example.com',
        httpClient: MockClient((req) async {
          final body = jsonDecode(req.body) as Map<String, Object?>;
          if (req.url.path.endsWith('design-agent')) {
            return _json({
              'text': 'ok',
              'design': {'elements': []},
              'imagePass': 'pass-1',
              'art': ' a storm cloud ',
            });
          }
          sent.add(body);
          return _json({
            'images': {'front': 'AAA', 'back': 'BBB', 'left': ''},
            'failed': ['right'],
          });
        }),
      );
      final ai = RemoteAiService(
        api,
        const ServerFeatures(designAgent: true, tryOn: true),
      );
      final reply = await ai.designAgent(
        message: 'a tee',
        design: {},
        history: const [],
      );
      expect(reply.art, 'a storm cloud');
      final out = await ai.designSides(
        'storm',
        images: [
          [1, 2, 3],
        ],
      );
      expect(sent.single['prompt'], 'storm');
      expect(sent.single['pass'], 'pass-1');
      expect(sent.single['images'], [
        base64Encode([1, 2, 3]),
      ]);
      expect(out.images, {
        'front': 'AAA',
        'back': 'BBB',
      }, reason: 'an empty picture is dropped');
      expect(out.failed, ['right']);

      await ai.designSides('again');
      expect(
        sent.last.containsKey('pass'),
        isFalse,
        reason: 'a pass is good for one go',
      );
      expect(sent.last.containsKey('images'), isFalse);
    });

    test(
      'maps the server refusing to "not connected" or a clear message',
      () async {
        ApiClient failing(int status, String message) => ApiClient(
          'https://api.example.com',
          httpClient: MockClient(
            (_) async => _json({
              'error': {'code': 'x', 'message': message},
            }, status),
          ),
        );
        expect(
          RemoteAiService(
            failing(503, 'off'),
            const ServerFeatures(),
          ).designSides('x'),
          throwsA(isA<AiUnavailable>()),
        );
        expect(
          RemoteAiService(
            failing(429, 'No creations left today.'),
            const ServerFeatures(),
          ).designSides('x'),
          throwsA(
            isA<AiFailure>().having(
              (e) => e.message,
              'message',
              contains('left today'),
            ),
          ),
        );
      },
    );
  });

  group('fonts', () {
    test('any Google Fonts family the assistant picks is used; an unknown name falls back to Outfit', () {
      final anton = DesignStudioUtils.getSafeGoogleFont(
        'Anton',
        textStyle: const TextStyle(fontSize: 20),
      );
      expect(anton.fontFamily, contains('Anton'));
      final marker = DesignStudioUtils.getSafeGoogleFont('Permanent Marker');
      expect(marker.fontFamily, contains('PermanentMarker'));
      final unknown = DesignStudioUtils.getSafeGoogleFont(
        'Totally Made Up Font',
      );
      expect(unknown.fontFamily, contains('Outfit'));
      expect(
        DesignStudioUtils.getSafeGoogleFont('Roboto').fontFamily,
        contains('Roboto'),
        reason: 'the listed fonts still work',
      );
    });
  });
}
