import 'dart:ui';

import 'custom_design.dart';

/// Geometry of one colourable zone, in the 1024×1024 space of the garment
/// photos in assets/images/garments (see tools/build_garment_assets.py).
class ZonePath {
  final List<List<Offset>> polygons;

  /// Ellipses as (centre, radiusX, radiusY); circles use rx == ry.
  final List<(Offset, double, double)> ellipses;

  const ZonePath({this.polygons = const [], this.ellipses = const []});

  /// The zone outline scaled by [scale] (display size / 1024).
  Path toPath(double scale) {
    final path = Path();
    for (final poly in polygons) {
      path.addPolygon([for (final p in poly) p * scale], true);
    }
    for (final (c, rx, ry) in ellipses) {
      path.addOval(
        Rect.fromCenter(
          center: c * scale,
          width: rx * 2 * scale,
          height: ry * 2 * scale,
        ),
      );
    }
    return path;
  }
}

/// A part of the garment the customer can colour separately.
class ColorZone {
  final String id;
  final String label;

  /// Trim zones follow the shared "trim" colour until set individually.
  final bool trim;

  const ColorZone(this.id, this.label, {this.trim = true});
}

/// One photographed view (front or back) of a style: the neutral shading
/// photo and where each colour zone sits on it.
class StyleView {
  final String asset;
  final Map<String, ZonePath> zones;
  const StyleView(this.asset, this.zones);
}

/// A garment style (crew tee, pocket tee, henley, polo...): its views and the
/// parts that can be coloured.
class GarmentStyle {
  final String id;
  final String label;
  final String description;
  final List<ColorZone> zones;
  final Map<DesignSide, StyleView> views;

  const GarmentStyle({
    required this.id,
    required this.label,
    required this.description,
    required this.zones,
    required this.views,
  });

  StyleView? viewFor(DesignSide side) => views[side];

  ColorZone? zoneById(String id) {
    for (final z in zones) {
      if (z.id == id) return z;
    }
    return null;
  }
}

Offset _o(double x, double y) => Offset(x, y);

// ── Shared zone geometry ────────────────────────────────────────────────────

const _sleeves = ColorZone('sleeves', 'Sleeves', trim: false);
const _cuffs = ColorZone('cuffs', 'Cuffs');
const _collar = ColorZone('collar', 'Collar');
const _pockets = ColorZone('pockets', 'Pockets');
const _placket = ColorZone('placket', 'Placket');
const _buttons = ColorZone('buttons', 'Buttons');

final _crewFront = <String, ZonePath>{
  'sleeves': ZonePath(
    polygons: [
      [
        _o(225, 115),
        _o(190, 150),
        _o(108, 415),
        _o(120, 440),
        _o(278, 470),
        _o(285, 400),
        _o(270, 300),
        _o(245, 190),
      ],
      [
        _o(800, 118),
        _o(835, 150),
        _o(912, 410),
        _o(900, 440),
        _o(745, 470),
        _o(740, 400),
        _o(750, 300),
        _o(775, 190),
      ],
    ],
  ),
  'cuffs': ZonePath(
    polygons: [
      [_o(100, 395), _o(280, 418), _o(285, 480), _o(110, 450)],
      [_o(920, 392), _o(745, 420), _o(742, 482), _o(905, 445)],
    ],
  ),
  'collar': ZonePath(ellipses: [(_o(505, 72), 138, 72)]),
};

final _pocketViewerLeft = [
  _o(305, 293),
  _o(445, 293),
  _o(445, 437),
  _o(375, 470),
  _o(305, 437),
];
final _pocketViewerRight = [
  _o(584, 293),
  _o(719, 293),
  _o(719, 440),
  _o(650, 473),
  _o(584, 440),
];

final _crewBack = <String, ZonePath>{
  'sleeves': ZonePath(
    polygons: [
      [
        _o(215, 125),
        _o(190, 160),
        _o(108, 410),
        _o(120, 440),
        _o(276, 468),
        _o(280, 400),
        _o(268, 300),
        _o(245, 200),
      ],
      [
        _o(800, 125),
        _o(830, 160),
        _o(912, 412),
        _o(900, 440),
        _o(748, 468),
        _o(742, 400),
        _o(752, 300),
        _o(775, 200),
      ],
    ],
  ),
  'cuffs': ZonePath(
    polygons: [
      [_o(104, 408), _o(278, 436), _o(276, 470), _o(116, 445)],
      [_o(912, 408), _o(745, 438), _o(748, 470), _o(900, 445)],
    ],
  ),
  'collar': ZonePath(
    polygons: [
      [_o(400, 34), _o(640, 34), _o(650, 70), _o(520, 95), _o(400, 70)],
    ],
  ),
};

final _henleyFront = <String, ZonePath>{
  'sleeves': ZonePath(
    polygons: [
      [
        _o(215, 110),
        _o(175, 150),
        _o(74, 400),
        _o(88, 425),
        _o(256, 462),
        _o(262, 400),
        _o(250, 300),
        _o(240, 200),
      ],
      [
        _o(830, 112),
        _o(870, 150),
        _o(950, 398),
        _o(940, 425),
        _o(768, 462),
        _o(762, 400),
        _o(772, 300),
        _o(785, 200),
      ],
    ],
  ),
  'cuffs': ZonePath(
    polygons: [
      [_o(68, 395), _o(258, 430), _o(256, 466), _o(90, 430)],
      [_o(955, 396), _o(764, 428), _o(768, 466), _o(940, 432)],
    ],
  ),
  'collar': ZonePath(ellipses: [(_o(495, 75), 138, 72)]),
  'placket': ZonePath(
    polygons: [
      [_o(488, 140), _o(540, 140), _o(540, 384), _o(488, 384)],
    ],
  ),
  'buttons': ZonePath(
    ellipses: [
      (_o(509, 164), 12, 12),
      (_o(513, 240), 12, 12),
      (_o(512, 318), 12, 12),
    ],
  ),
};

final _poloFront = <String, ZonePath>{
  'sleeves': ZonePath(
    polygons: [
      [
        _o(215, 125),
        _o(160, 170),
        _o(108, 445),
        _o(128, 470),
        _o(262, 492),
        _o(268, 420),
        _o(262, 300),
        _o(240, 200),
      ],
      [
        _o(800, 125),
        _o(850, 170),
        _o(916, 440),
        _o(900, 468),
        _o(752, 492),
        _o(745, 420),
        _o(750, 300),
        _o(775, 200),
      ],
    ],
  ),
  'cuffs': ZonePath(
    polygons: [
      [_o(104, 425), _o(270, 455), _o(263, 492), _o(124, 468)],
      [_o(918, 432), _o(752, 462), _o(752, 495), _o(900, 470)],
    ],
  ),
  'collar': ZonePath(
    polygons: [
      [
        _o(384, 175),
        _o(380, 60),
        _o(407, 38),
        _o(520, 32),
        _o(606, 38),
        _o(640, 70),
        _o(654, 175),
        _o(615, 160),
        _o(535, 125),
        _o(510, 140),
        _o(458, 182),
      ],
    ],
  ),
  'placket': ZonePath(
    polygons: [
      [_o(488, 175), _o(536, 175), _o(536, 337), _o(488, 337)],
    ],
  ),
  'buttons': ZonePath(
    ellipses: [(_o(478, 168), 10, 10), (_o(512, 243), 10, 10)],
  ),
};

final _poloBack = <String, ZonePath>{
  'sleeves': ZonePath(
    polygons: [
      [
        _o(235, 130),
        _o(200, 165),
        _o(140, 410),
        _o(150, 440),
        _o(285, 468),
        _o(290, 400),
        _o(280, 300),
        _o(255, 200),
      ],
      [
        _o(795, 130),
        _o(830, 165),
        _o(885, 410),
        _o(872, 440),
        _o(748, 470),
        _o(742, 400),
        _o(750, 300),
        _o(775, 200),
      ],
    ],
  ),
  'cuffs': ZonePath(
    polygons: [
      [_o(138, 405), _o(288, 435), _o(286, 472), _o(150, 448)],
      [_o(886, 405), _o(744, 436), _o(748, 470), _o(872, 445)],
    ],
  ),
  'collar': ZonePath(
    polygons: [
      [
        _o(372, 95),
        _o(385, 50),
        _o(420, 36),
        _o(590, 36),
        _o(620, 55),
        _o(626, 95),
        _o(500, 100),
      ],
    ],
  ),
};

const _dir = 'assets/images/garments';

StyleView _crewBackView() => StyleView('$_dir/crew_back.png', _crewBack);

Map<String, ZonePath> _withPockets(List<List<Offset>> pockets) => {
  ..._crewFront,
  'pockets': ZonePath(polygons: pockets),
};

/// All styles offered for the T-shirt category.
class GarmentStyles {
  GarmentStyles._();

  static const String defaultId = 'crew';

  static final List<GarmentStyle> all = [
    GarmentStyle(
      id: 'crew',
      label: 'Crew tee',
      description: 'Classic round neck',
      zones: const [_sleeves, _cuffs, _collar],
      views: {
        DesignSide.front: StyleView('$_dir/crew_front.png', _crewFront),
        DesignSide.back: _crewBackView(),
      },
    ),
    GarmentStyle(
      id: 'crew_pocket_left',
      label: 'Pocket tee · left',
      description: 'Chest pocket on the wearer\'s left',
      zones: const [_sleeves, _cuffs, _collar, _pockets],
      views: {
        DesignSide.front: StyleView(
          '$_dir/crew_pocket_left_front.png',
          _withPockets([_pocketViewerRight]),
        ),
        DesignSide.back: _crewBackView(),
      },
    ),
    GarmentStyle(
      id: 'crew_pocket_right',
      label: 'Pocket tee · right',
      description: 'Chest pocket on the wearer\'s right',
      zones: const [_sleeves, _cuffs, _collar, _pockets],
      views: {
        DesignSide.front: StyleView(
          '$_dir/crew_pocket_right_front.png',
          _withPockets([_pocketViewerLeft]),
        ),
        DesignSide.back: _crewBackView(),
      },
    ),
    GarmentStyle(
      id: 'crew_pocket_both',
      label: 'Pocket tee · both',
      description: 'Two chest pockets',
      zones: const [_sleeves, _cuffs, _collar, _pockets],
      views: {
        DesignSide.front: StyleView(
          '$_dir/crew_pocket_both_front.png',
          _withPockets([_pocketViewerLeft, _pocketViewerRight]),
        ),
        DesignSide.back: _crewBackView(),
      },
    ),
    GarmentStyle(
      id: 'henley',
      label: 'Henley',
      description: 'Buttoned placket, round neck',
      zones: const [_sleeves, _cuffs, _collar, _placket, _buttons],
      views: {
        DesignSide.front: StyleView('$_dir/henley_front.png', _henleyFront),
        // No separate henley back photo: it is a plain crew back.
        DesignSide.back: _crewBackView(),
      },
    ),
    GarmentStyle(
      id: 'polo',
      label: 'Polo',
      description: 'Collar, placket and buttons',
      zones: const [_sleeves, _cuffs, _collar, _placket, _buttons],
      views: {
        DesignSide.front: StyleView('$_dir/polo_front.png', _poloFront),
        DesignSide.back: StyleView('$_dir/polo_back.png', _poloBack),
      },
    ),
  ];

  static GarmentStyle byId(String? id) =>
      all.firstWhere((s) => s.id == id, orElse: () => all.first);

  /// Style implied by designs saved before styles existed.
  static String fromLegacy({String? collar, String? pocket}) {
    if (collar == 'polo') return 'polo';
    return switch (pocket) {
      'left' => 'crew_pocket_left',
      'right' => 'crew_pocket_right',
      'both' => 'crew_pocket_both',
      _ => defaultId,
    };
  }
}
