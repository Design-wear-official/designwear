import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/screens/studio/editor/canvas/design_canvas.dart';
import 'package:designwear/screens/studio/editor/canvas/garment_registry.dart';
import 'package:designwear/screens/studio/editor/panels/color_panel.dart';
import 'package:designwear/screens/studio/editor/widgets/dialogs/layers_sheet.dart';
import 'package:designwear/services/ai/ai_agent_service.dart';
import 'package:designwear/services/ai/ai_service.dart';
import 'package:designwear/services/ai/layers.dart';
import 'package:designwear/services/ai/remote_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, Object?> _layer(
  String key,
  String? side, {
  bool ok = true,
  bool provisional = false,
}) => {
  'key': key,
  'side': side,
  'label': key,
  'status': ok ? 'ok' : 'failed',
  if (!ok) 'reason': 'not_drawn',
  'url': ok ? 'https://api.example.com/v1/layers/j1/$key.png?sig=s' : null,
  'printUrl': ok
      ? 'https://api.example.com/v1/layers/j1/$key.png?sig=s&print=1'
      : null,
  'warnings': <String>[],
  'width': key.startsWith('sleeve') ? 1200 : 3600,
  'height': key.startsWith('sleeve') ? 1200 : 4800,
  'dpi': 300,
  'provisional': provisional,
};

Map<String, Object?> _job({List<Map<String, Object?>>? layers}) => {
  'id': 'j1',
  'name': 'Storm',
  'garment': 'tshirt',
  'layers':
      layers ??
      [
        _layer('front', 'front'),
        _layer('back', 'back'),
        _layer('sleeve_left', 'left', provisional: true),
        _layer('sleeve_right', 'right', provisional: true),
        _layer('neck_label', null),
      ],
  'urls': {
    'sheet': 'https://api.example.com/v1/layers/j1/sheet.png?sig=s',
    'sheetPdf': 'https://api.example.com/v1/layers/j1/sheet.pdf?sig=s',
    'model': 'https://api.example.com/v1/layers/j1/model.glb?sig=s',
    'views': {
      for (final v in ['front', 'right', 'back', 'left'])
        v: 'https://api.example.com/v1/layers/j1/view-$v.png?sig=s',
    },
  },
  'complete': true,
};

class _Ai extends UnconfiguredAiService {
  _Ai({this.job, this.unsupported = false, this.refuse});
  final Map<String, Object?>? job;
  final bool unsupported;
  final String? refuse;
  final prompts = <String>[];
  final fetched = <String>[];
  String? garment;
  String? color;
  List<String>? sides;

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
  }) async => const DesignAgentReply(
    text: 'Here you go.',
    art: 'a storm',
    design: {'elements': []},
  );

  @override
  Future<LayerJob> designLayers(
    String prompt, {
    List<List<int>> images = const [],
    String? garment,
    String? color,
    String? name,
    List<String> sides = const ['front', 'back', 'left', 'right'],
  }) async {
    prompts.add(prompt);
    this.garment = garment;
    this.color = color;
    this.sides = sides;
    if (refuse != null) throw AiFailure(refuse!);
    if (unsupported) throw const LayersUnsupported();
    return LayerJob.fromJson(job!);
  }

  @override
  Future<List<int>> fetchLayerImage(String url) async {
    fetched.add(url);
    return [1, 2, 3];
  }

  @override
  Future<DesignSides> designSides(
    String prompt, {
    List<List<int>> images = const [],
  }) async {
    prompts.add('sides:$prompt');
    return DesignSides(
      images: {
        'front': base64Encode([9]),
      },
    );
  }
}

http.Response _json(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  late AiService original;
  setUp(() => original = AiService.instance);
  tearDown(() => AiService.instance = original);

  group('LayerJob', () {
    test(
      'reads layers, views and links, and drops links that are not https',
      () {
        final j = LayerJob.fromJson({
          ..._job(),
          'urls': {
            'sheet': 'http://evil.example.com/s.png',
            'sheetPdf': 'https://api.example.com/s.pdf',
            'views': {
              'front': 'javascript:alert(1)',
              'back': 'https://x.test/b',
            },
          },
        });
        expect(j.layers.length, 5);
        expect(j.layers.first.side, 'front');
        expect(j.layers[2].provisional, isTrue);
        expect(j.sheetUrl, isNull);
        expect(j.sheetPdfUrl, 'https://api.example.com/s.pdf');
        expect(j.views.keys, ['back']);
        expect(j.viewFor('front'), isNull);
      },
    );

    test('a placement says its size in pixels and inches', () {
      final p = PrintPlacement.fromJson({
        'key': 'front',
        'label': 'Front',
        'width': 3600,
        'height': 4800,
        'dpi': 300,
      });
      expect(p.sizeText, '3600 × 4800 px · 12 × 16 in at 300 dpi');
      final s = PrintPlacement.fromJson({
        'key': 'sleeve_left',
        'label': 'Left sleeve',
        'width': 1200,
        'height': 1100,
        'dpi': 300,
        'provisional': true,
      });
      expect(s.sizeText, '1200 × 1100 px · 4 × 3.7 in at 300 dpi');
      expect(PrintPlacement.sideOf('sleeve_right'), 'right');
      expect(PrintPlacement.sideOf('neck_label'), isNull);
    });

    test('a garment keeps its placements from the list', () {
      final g = Garment.fromJson({
        'id': 'tshirt',
        'label': 'T',
        'placements': [
          {'key': 'sleeve_left', 'label': 'L', 'width': 1200, 'height': 1200},
          {'broken': true},
        ],
      });
      expect(g.placementFor(DesignSide.left)!.width, 1200);
      expect(g.placementFor(DesignSide.front), isNull);
    });
  });

  group('RemoteAiService.designLayers', () {
    RemoteAiService remote(
      Future<http.Response> Function(http.Request) h,
      List<Map<String, Object?>> sent,
    ) => RemoteAiService(
      ApiClient(
        'https://api.example.com',
        httpClient: MockClient((req) async {
          if (req.method == 'POST') {
            sent.add({
              'path': req.url.path,
              ...jsonDecode(req.body) as Map<String, Object?>,
            });
          }
          return h(req);
        }),
      ),
      const ServerFeatures(designAgent: true, tryOn: true),
    );

    test('sends the prompt, garment, colour, pictures and the pass once; reads the job', () async {
      final sent = <Map<String, Object?>>[];
      final ai = remote((req) async {
        if (req.url.path.endsWith('design-agent')) {
          return _json({
            'text': 'ok',
            'design': {'elements': []},
            'imagePass': 'pass-1',
          });
        }
        return _json(_job());
      }, sent);
      await ai.designAgent(message: 'x', design: {}, history: const []);
      final job = await ai.designLayers(
        'storm',
        garment: 'tshirt',
        color: '0xFF112233',
        name: 'Storm',
        images: [
          [1, 2],
        ],
      );
      final body = sent.last;
      expect(body['path'], '/v1/ai/design-layers');
      expect(body['prompt'], 'storm');
      expect(body['garment'], 'tshirt');
      expect(body['color'], '0xFF112233');
      expect(body['pass'], 'pass-1');
      expect(body['sides'], ['front', 'back', 'left', 'right']);
      expect(body['images'], [
        base64Encode([1, 2]),
      ]);
      expect(job.layers.length, 5);
      await ai.designLayers('again');
      expect(sent.last.containsKey('pass'), isFalse);
    });

    test(
      'a missing route is "unsupported" and keeps the pass for the fallback',
      () async {
        final sent = <Map<String, Object?>>[];
        final ai = remote((req) async {
          if (req.url.path.endsWith('design-agent')) {
            return _json({
              'text': 'ok',
              'design': {'elements': []},
              'imagePass': 'p9',
            });
          }
          if (req.url.path.endsWith('design-layers')) {
            return _json({
              'error': {'code': 'not_found', 'message': 'nope'},
            }, 404);
          }
          return _json({
            'images': {'front': 'AAA'},
          });
        }, sent);
        await ai.designAgent(message: 'x', design: {}, history: const []);
        await expectLater(
          ai.designLayers('storm'),
          throwsA(isA<LayersUnsupported>()),
        );
        await ai.designSides('storm');
        expect(sent.last['pass'], 'p9');
      },
    );

    test('a protected name shows the server\'s own message', () async {
      final ai = remote(
        (_) async => _json({
          'error': {'code': 'ip_blocked', 'message': 'That name is protected.'},
        }, 422),
        [],
      );
      await expectLater(
        ai.designLayers('a famous mouse'),
        throwsA(
          isA<AiFailure>().having(
            (e) => e.message,
            'message',
            'That name is protected.',
          ),
        ),
      );
    });

    test(
      'downloads a layer from its signed link without a sign-in header',
      () async {
        Map<String, String>? headers;
        final ai = RemoteAiService(
          ApiClient(
            'https://api.example.com',
            httpClient: MockClient((req) async {
              headers = req.headers;
              return http.Response.bytes([7, 7], 200);
            }),
          ),
          const ServerFeatures(designAgent: true, tryOn: true),
        );
        expect(
          await ai.fetchLayerImage('https://api.example.com/x.png?sig=s'),
          [7, 7],
        );
        expect(headers!.containsKey('authorization'), isFalse);
        await expectLater(
          ai.fetchLayerImage('http://evil.example.com/x.png'),
          throwsA(isA<AiFailure>()),
        );
      },
    );
  });

  group('the assistant draws from layers', () {
    test(
      'each layer becomes an image on its side, and the job comes with it',
      () async {
        final fake = _Ai(job: _job());
        AiService.instance = fake;
        final r = await AIAgentService().sendMessage(
          'make it better',
          CustomDesign(baseColor: '0xFF112233', name: 'Storm'),
          garment: 'tshirt',
        );
        final els = r.updatedDesign!.elements;
        expect(els.length, 4, reason: 'the neck label has no studio side');
        expect(els.map((e) => e.side).toSet(), {
          DesignSide.front,
          DesignSide.back,
          DesignSide.left,
          DesignSide.right,
        });
        expect(els.every((e) => e.content == base64Encode([1, 2, 3])), isTrue);
        expect(
          fake.fetched.every((u) => !u.contains('print=1')),
          isTrue,
          reason: 'the transparent layer, not the print file',
        );
        expect(fake.prompts.single, 'a storm');
        expect(fake.garment, 'tshirt');
        expect(fake.color, '0xFF112233');
        expect(r.layerJob!.id, 'j1');
        expect(r.previewBase64, base64Encode([1, 2, 3]));
      },
    );

    test('a layer that failed is said so, the rest still arrive', () async {
      AiService.instance = _Ai(
        job: _job(
          layers: [_layer('front', 'front'), _layer('back', 'back', ok: false)],
        ),
      );
      final r = await AIAgentService().sendMessage('x', CustomDesign());
      expect(r.updatedDesign!.elements.length, 1);
      expect(r.text, contains("couldn't draw the back"));
    });

    test('an older API falls back to one picture per face', () async {
      final fake = _Ai(unsupported: true);
      AiService.instance = fake;
      final r = await AIAgentService().sendMessage('x', CustomDesign());
      expect(fake.prompts, ['a storm', 'sides:a storm']);
      expect(r.updatedDesign!.elements.single.side, DesignSide.front);
      expect(r.layerJob, isNull);
    });

    test('a refusal is shown, the design edit stays', () async {
      AiService.instance = _Ai(refuse: 'That name is protected.');
      final r = await AIAgentService().sendMessage('x', CustomDesign());
      expect(r.text, contains('That name is protected.'));
      expect(r.updatedDesign, isNotNull);
    });
  });

  group('Layers & sheet', () {
    Future<List<Uri>> show(WidgetTester tester, Garment g) async {
      tester.view.physicalSize = const Size(900, 3000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final opened = <Uri>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LayersSheet(
              job: LayerJob.fromJson(_job()),
              garment: g,
              open: (u) async {
                opened.add(u);
                return true;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      return opened;
    }

    testWidgets(
      'shows each print area\'s size, the provisional note, and opens the files',
      (tester) async {
        final opened = await show(
          tester,
          Garment.fromJson({
            'id': 'tshirt',
            'label': 'T-Shirt',
            'placements': [
              {
                'key': 'front',
                'label': 'Front',
                'width': 3600,
                'height': 4800,
                'dpi': 300,
              },
            ],
          }),
        );
        expect(
          find.text('3600 × 4800 px · 12 × 16 in at 300 dpi'),
          findsWidgets,
        );
        expect(find.byKey(const ValueKey('size-sleeve_left')), findsOneWidget);
        expect(find.byKey(const ValueKey('provisional-note')), findsOneWidget);
        for (final v in ['front', 'right', 'back', 'left']) {
          expect(find.byKey(ValueKey('view-$v')), findsOneWidget);
        }
        await tester.tap(find.byKey(const ValueKey('sheet-pdf')));
        await tester.tap(find.byKey(const ValueKey('sheet-png')));
        await tester.ensureVisible(find.byKey(const ValueKey('print-back')));
        await tester.tap(find.byKey(const ValueKey('print-back')));
        await tester.ensureVisible(find.byKey(const ValueKey('model-link')));
        await tester.tap(find.byKey(const ValueKey('model-link')));
        expect(opened.map((u) => u.path.split('/').last), [
          'sheet.pdf',
          'sheet.png',
          'back.png',
          'model.glb',
        ]);
        expect(opened[2].queryParameters['print'], '1');
      },
    );
  });

  group('the canvas', () {
    Future<void> pump(
      WidgetTester tester, {
      String? mockup,
      VoidCallback? layers,
    }) async {
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DesignCanvas(
                design: CustomDesign(),
                selectedElementId: null,
                onElementSelected: (_) {},
                onElementPreview: (_) {},
                onElementCommit: () {},
                onElementDelete: (_) {},
                onSideChanged: (_) {},
                mockupUrl: mockup,
                onOpenLayers: layers,
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }

    testWidgets(
      'shows the mock-up only when given one, and survives it not loading',
      (tester) async {
        await pump(tester);
        expect(find.byKey(const ValueKey('mockup-view')), findsNothing);
        await pump(
          tester,
          mockup: 'https://api.example.com/v1/layers/j1/view-front.png?sig=s',
        );
        expect(find.byKey(const ValueKey('mockup-view')), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('the Layers & sheet button appears only with layers', (
      tester,
    ) async {
      await pump(tester);
      expect(find.text('Layers & sheet'), findsNothing);
      var tapped = 0;
      await pump(tester, layers: () => tapped++);
      await tester.tap(find.byKey(const ValueKey('open-layers')));
      expect(tapped, 1);
    });
  });

  group('garment styles and colours', () {
    setUp(GarmentRegistry.reset);
    tearDown(GarmentRegistry.reset);

    Garment tank() => Garment.fromJson({
      'id': 'tank',
      'label': 'Tank',
      'style': 'TANK',
      'colors': [
        {'name': 'Ink', 'hex': '#1C1C1E'},
        {'name': 'Bad', 'hex': 'nope'},
        {'name': 'Chalk', 'hex': 'F5F5F0'},
      ],
    });

    test('style and colours are read; a bad colour is dropped', () {
      final g = tank();
      expect(g.style, 'tank');
      expect(g.hasSleeves, isFalse);
      expect(g.colors.map((c) => c.name), ['Ink', 'Chalk']);
      expect(g.colors.first.color.toARGB32(), 0xFF1C1C1E);
      expect(Garment.fromJson({'id': 'a', 'label': 'A'}).hasSleeves, isTrue);
    });

    testWidgets('the colour picker offers the garment\'s own colours', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      CustomDesign? picked;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPanel(
              design: CustomDesign(baseColor: '0xFF1C1C1E'),
              onDesignUpdate: (d) => picked = d,
              garmentColors: tank().colors,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('TEE COLOUR — Ink'), findsOneWidget);
      final shown = find.byType(GestureDetector);
      expect(shown, findsWidgets);
      expect(picked, isNull);
    });

    testWidgets('a tank top has no sleeve sides to switch to', (tester) async {
      GarmentRegistry.updateFromBackend([tank()]);
      tester.view.physicalSize = const Size(1000, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Future<void> pump(String garment) => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DesignCanvas(
                design: CustomDesign(),
                selectedElementId: null,
                garmentType: garment,
                onElementSelected: (_) {},
                onElementPreview: (_) {},
                onElementCommit: () {},
                onElementDelete: (_) {},
                onSideChanged: (_) {},
              ),
            ),
          ),
        ),
      );
      await pump('tank');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('LEFT'), findsNothing);
      expect(find.text('RIGHT'), findsNothing);
      expect(find.text('BACK'), findsOneWidget);
      await pump('tshirt');
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('LEFT'), findsOneWidget);
    });

    test('a tank asks for front and back only; a polo front sits below the placket', () async {
      GarmentRegistry.updateFromBackend([
        tank(),
        Garment.fromJson({'id': 'polo', 'label': 'Polo', 'style': 'polo'}),
      ]);
      final fake = _Ai(job: _job());
      AiService.instance = fake;
      await AIAgentService().sendMessage('x', CustomDesign(), garment: 'tank');
      expect(fake.sides, ['front', 'back']);
      final r = await AIAgentService().sendMessage(
        'x',
        CustomDesign(),
        garment: 'polo',
      );
      expect(fake.sides, ['front', 'back', 'left', 'right']);
      final front = r.updatedDesign!.elementsForSide(DesignSide.front).single;
      expect(front.y, greaterThan(0));
    });
  });
}
