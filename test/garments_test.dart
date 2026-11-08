import 'dart:convert';

import 'package:designwear/api/api_client.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/screens/studio/editor/canvas/design_canvas.dart';
import 'package:designwear/screens/studio/editor/canvas/garment_registry.dart';
import 'package:designwear/services/studio/garment_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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

final _list = {
  'data': [
    {
      'id': 'tshirt',
      'label': 'Classic Tee',
      'productType': 'tshirt',
      'basePrice': 549,
      'frontImageUrl': null,
      'backImageUrl': null,
      'supportsCollarPocket': true,
      'sortOrder': 0,
    },
    {
      'id': 'longsleeve',
      'label': 'Long Sleeve',
      'productType': 'longsleeve',
      'basePrice': 799.5,
      'frontImageUrl': 'https://img.invalid/longsleeve-front.png',
      'backImageUrl': null,
      'supportsCollarPocket': false,
      'sortOrder': 1,
    },
    {'id': 'bare', 'label': 'No Photo Yet', 'basePrice': null},
  ],
};

void main() {
  setUp(GarmentRegistry.reset);
  tearDown(GarmentRegistry.reset);

  group('GarmentService', () {
    test('the list extends and replaces the bundled garments', () async {
      expect(GarmentRegistry.selectable.map((g) => g.id), ['tshirt']);
      await GarmentService.loadGarments(_api(_list));
      final t = GarmentRegistry.byId('tshirt');
      expect(t.label, 'Classic Tee');
      expect(t.basePrice, 549);
      expect(
        t.frontAsset,
        isNotNull,
        reason: 'the bundled picture stays as the fallback',
      );
      final l = GarmentRegistry.byId('longsleeve');
      expect(l.label, 'Long Sleeve');
      expect(l.basePrice, 799.5);
      expect(l.imageUrl(DesignSide.front), startsWith('https://'));
      expect(l.isNetworkImage(DesignSide.front), isTrue);
      expect(GarmentRegistry.byId('bare').hasAsset(DesignSide.front), isFalse);
    });

    test(
      'the chooser offers exactly the business\'s list once it arrives',
      () async {
        await GarmentService.loadGarments(_api(_list));
        expect(GarmentRegistry.selectable.map((g) => g.id), [
          'tshirt',
          'longsleeve',
          'bare',
        ]);
      },
    );

    test('a failure keeps the bundled defaults and never throws', () async {
      await GarmentService.loadGarments(_api({'error': 'x'}, status: 500));
      await GarmentService.loadGarments(
        ApiClient(
          'https://api.example.com',
          httpClient: MockClient((_) async => throw Exception('offline')),
        ),
      );
      await GarmentService.loadGarments(null);
      await GarmentService.loadGarments(_api({'data': 'nonsense'}));
      await GarmentService.loadGarments(_api({'data': []}));
      expect(GarmentRegistry.selectable.map((g) => g.id), ['tshirt']);
      expect(GarmentRegistry.byId('tshirt').label, 'T-Shirt');
      expect(GarmentRegistry.byId('tshirt').basePrice, isNull);
    });

    test('a malformed row is skipped, the rest still count', () async {
      await GarmentService.loadGarments(
        _api({
          'data': [
            {'label': 'no id'},
            {'id': 'cap2', 'label': 'Cap'},
          ],
        }),
      );
      expect(GarmentRegistry.selectable.map((g) => g.id), ['cap2']);
    });

    test('the registry tells listeners when the list changes', () async {
      final before = GarmentRegistry.revision.value;
      await GarmentService.loadGarments(_api(_list));
      expect(GarmentRegistry.revision.value, greaterThan(before));
    });
  });

  group('the canvas', () {
    Future<void> show(WidgetTester tester, String garment) async {
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
      await tester.pump(const Duration(milliseconds: 200));
    }

    testWidgets(
      'an added garment with a photo that cannot load does not crash',
      (tester) async {
        await GarmentService.loadGarments(_api(_list));
        await show(tester, 'longsleeve');
        expect(tester.takeException(), isNull);
        expect(find.byType(DesignCanvas), findsOneWidget);
      },
    );

    testWidgets(
      'an added garment with no photo shows the coming-soon placeholder',
      (tester) async {
        await GarmentService.loadGarments(_api(_list));
        await show(tester, 'bare');
        expect(tester.takeException(), isNull);
        expect(find.byType(Image), findsNothing);
      },
    );
  });
}
