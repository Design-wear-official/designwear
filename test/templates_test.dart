import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/screens/studio/editor/canvas/garment_registry.dart';
import 'package:designwear/screens/studio/editor/panels/color_panel.dart';
import 'package:designwear/services/studio/design_template_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

ApiClient _api(Object body, {int status = 200}) => ApiClient(
  'https://api.example.com',
  httpClient: MockClient(
    (req) async => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json'},
    ),
  ),
);

// What GET /v1/templates serves for one row of the business's list.
const _list = {
  'data': [
    {
      'id': 'sunset-vibes',
      'name': 'Sunset Vibes',
      'description': 'Starter design',
      'category': 'graphic',
      'thumbnailUrl': null,
      'tags': ['starter'],
      'sortOrder': 1,
      'design': {
        'name': 'Sunset Vibes',
        'templateId': 'sunset-vibes',
        'productType': 'T-Shirt',
        'baseColor': '0xFFE65100',
        'elements': [
          {
            'id': 'sunset-vibes_1',
            'type': 'text',
            'content': 'SUNSET VIBES',
            'x': -60,
            'y': -30,
            'size': 30,
            'color': '0xFFFFFFFF',
            'rotation': 0,
            'opacity': 1,
            'side': 'front',
            'properties': {'fontFamily': 'Oswald', 'bold': true},
          },
        ],
      },
    },
    {'id': 'broken'},
  ],
};

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DesignTemplateService.reset();
  });
  tearDown(DesignTemplateService.reset);

  group('starter designs', () {
    test('the app ships none of its own', () async {
      final s = DesignTemplateService();
      expect(s.getStarterDesigns(), isEmpty);
      expect(await s.getAllTemplates(), isEmpty);
    });

    test('they come from the business\'s list; a bad row is skipped', () async {
      await DesignTemplateService.loadTemplates(_api(_list));
      final s = DesignTemplateService();
      final starters = s.getStarterDesigns();
      expect(starters.map((d) => d.name), ['Sunset Vibes']);
      expect(starters.single.baseColor, '0xFFE65100');
      expect(starters.single.elements.single.content, 'SUNSET VIBES');
      expect(starters.single.elements.single.type, DesignElementType.text);
      expect((await s.getAllTemplates()).single.id, 'sunset-vibes');
      expect(s.getTemplateById('sunset-vibes')?.thumbnailUrl, '');
    });

    test('a failure keeps the list as it was and never throws', () async {
      await DesignTemplateService.loadTemplates(_api(_list));
      await DesignTemplateService.loadTemplates(
        _api({'error': 'x'}, status: 500),
      );
      await DesignTemplateService.loadTemplates(null);
      expect(DesignTemplateService().getStarterDesigns(), hasLength(1));
    });

    test('an empty list from the business clears them', () async {
      await DesignTemplateService.loadTemplates(_api(_list));
      await DesignTemplateService.loadTemplates(_api({'data': []}));
      expect(DesignTemplateService().getStarterDesigns(), isEmpty);
    });
  });

  testWidgets(
    'without the business\'s colours only white and black are offered',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      expect(GarmentRegistry.fallbackColors.map((c) => c.name), [
        'White',
        'Black',
      ]);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ColorPanel(
              design: CustomDesign(baseColor: '0xFF1C1C1E'),
              onDesignUpdate: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('TEE COLOUR — Black'), findsOneWidget);
    },
  );
}
