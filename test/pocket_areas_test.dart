import 'package:designwear/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
