import 'dart:io';

import 'package:designwear/screens/studio/editor/canvas/design_canvas.dart';
import 'package:flutter/material.dart';
import 'package:designwear/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  styleSwitchTests();
  listedGarmentTests();
  pocketButtonTests();
  vectorStyleTests();
  test('pocket sides parse and are small print areas', () {
    expect(DesignSide.fromString('leftPocket'), DesignSide.leftPocket);
    expect(DesignSide.fromString('rightPocket'), DesignSide.rightPocket);
    expect(DesignSide.leftPocket.isPocket, isTrue);
    expect(DesignSide.leftPocket.isSleeve, isFalse);
    expect(DesignSide.right.isSmallArea, isTrue);
    expect(DesignSide.front.isSmallArea, isFalse);
  });

  test('per-area colours round-trip and default to auto', () {
    final d = CustomDesign().copyWith(
      collarColor: '0xFFFF0000',
      pocketColor: '0xFF00FF00',
      cuffColor: '0xFF0000FF',
    );
    final back = CustomDesign.fromJson(d.toJson());
    expect(back.collarColor, '0xFFFF0000');
    expect(back.pocketColor, '0xFF00FF00');
    expect(back.cuffColor, '0xFF0000FF');
    expect(CustomDesign.fromJson(const {}).pocketColor, 'auto');
  });

  test('styles: legacy designs map to a style; zones inherit trim', () {
    expect(
      CustomDesign.fromJson({'pocketStyle': 'both'}).styleId,
      'crew_pocket_both',
    );
    expect(CustomDesign.fromJson({'collarStyle': 'polo'}).styleId, 'polo');
    expect(CustomDesign.fromJson(const {}).styleId, 'crew');

    final d = CustomDesign(styleId: 'polo', trimColor: '0xFF123456');
    expect(d.zoneHex('collar'), '0xFF123456'); // trim zone follows trim
    expect(d.zoneHex('sleeves'), isNull); // sleeves take the garment colour
    final own = d.copyWith(partColors: {'collar': '0xFF654321'});
    expect(own.zoneHex('collar'), '0xFF654321');
    expect(
      CustomDesign.fromJson(own.toJson()).partColors['collar'],
      '0xFF654321',
    );
  });

  test('every style has photo views whose zones are all declared', () {
    for (final st in GarmentStyles.all) {
      expect(st.viewFor(DesignSide.front), isNotNull, reason: st.id);
      expect(st.viewFor(DesignSide.back), isNotNull, reason: st.id);
      for (final view in st.views.values) {
        for (final id in view.zones.keys) {
          expect(st.zoneById(id), isNotNull, reason: '${st.id}/$id');
        }
      }
    }
  });
}

void vectorStyleTests() {
  test('vector styles draw every colour zone they declare', () {
    // Each zone must appear on at least one side (a cap strap is back-only).
    for (final st in GarmentStyles.all) {
      final front = st.viewFor(DesignSide.front)!.vector;
      final back = st.viewFor(DesignSide.back)!.vector;
      if (front == null || back == null) continue;
      final drawn = {
        for (final p in [...front, ...back]) p.zone,
      };
      for (final z in st.zones) {
        expect(drawn, contains(z.id), reason: '${st.id}/${z.id}');
      }
    }
  });

  test('each garment resolves to a style; others fall back', () {
    for (final g in ['tshirt', 'hoodie', 'cap', 'totebag']) {
      expect(GarmentStyles.resolve(g, 'nope'), isNotNull, reason: g);
    }
    expect(GarmentStyles.resolve('hoodie', 'crew')!.id, 'hoodie');
    expect(GarmentStyles.resolve('mug', 'crew'), isNull);
  });
}

void pocketButtonTests() {
  test('a pocket print area exists only for a pocket the style has', () {
    final crew = GarmentStyles.byId('crew');
    expect(crew.hasPocket(DesignSide.leftPocket), isFalse);
    expect(crew.hasPocket(DesignSide.rightPocket), isFalse);
    final left = GarmentStyles.byId('crew_pocket_left');
    expect(left.hasPocket(DesignSide.leftPocket), isTrue);
    expect(left.hasPocket(DesignSide.rightPocket), isFalse);
    final both = GarmentStyles.byId('crew_pocket_both');
    expect(both.hasPocket(DesignSide.leftPocket), isTrue);
    expect(both.hasPocket(DesignSide.rightPocket), isTrue);
    expect(
      GarmentStyles.byId('polo').hasPocket(DesignSide.leftPocket),
      isFalse,
    );
  });
}

void listedGarmentTests() {
  test('every garment the business lists has a style with photos', () {
    for (final g in [
      'tshirt',
      'hoodie',
      'sweatshirt',
      'tank',
      'polo',
      'cap',
      'totebag',
    ]) {
      final style = GarmentStyles.resolve(g, 'crew');
      expect(style, isNotNull, reason: g);
      expect(style!.viewFor(DesignSide.front), isNotNull, reason: g);
      expect(style.viewFor(DesignSide.back), isNotNull, reason: g);
      expect(GarmentStyles.forGarment(g), isNotEmpty, reason: g);
    }
    expect(GarmentStyles.resolve('sweatshirt', 'crew')!.id, 'sweatshirt');
    expect(GarmentStyles.resolve('tank', 'crew')!.id, 'tank');
  });
}

void styleSwitchTests() {
  testWidgets(
    'switching style swaps the garment photo (the old one is not kept)',
    (tester) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      Widget canvas(String styleId) => MaterialApp(
        home: DesignCanvas(
          design: CustomDesign(styleId: styleId),
          garmentType: 'tshirt',
          selectedElementId: null,
          side: DesignSide.front,
          bare: true,
          onElementSelected: (_) {},
          onElementPreview: (_) {},
          onElementCommit: () {},
          onElementDelete: (_) {},
          onSideChanged: (_) {},
        ),
      );
      final tank = GarmentStyles.byId('tank').viewFor(DesignSide.front)!.asset;
      final polo = GarmentStyles.byId('polo').viewFor(DesignSide.front)!.asset;
      await tester.pumpWidget(canvas('tank'));
      expect(find.byKey(ValueKey(tank)), findsWidgets);
      await tester.pumpWidget(canvas('polo'));
      expect(find.byKey(ValueKey(polo)), findsWidgets);
      expect(find.byKey(ValueKey(tank)), findsNothing);
    },
  );

  test('style photos are small WebP files', () {
    for (final st in GarmentStyles.all) {
      for (final v in st.views.values) {
        if (v.asset.isEmpty) continue;
        expect(v.asset.endsWith('.webp'), isTrue, reason: v.asset);
        expect(
          File(v.asset).lengthSync(),
          lessThan(150 * 1024),
          reason: v.asset,
        );
      }
    }
  });
}
