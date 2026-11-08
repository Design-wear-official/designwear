import 'dart:ui';

import 'custom_design.dart';
import 'vector_garments.dart';

/// Geometry of one colourable zone, in the 1024×1024 space of the garment
/// photos in assets/images/garments (see tools/build_garment_assets.py).
class ZonePath {
  final List<List<Offset>> polygons;

  /// Fill with the even-odd rule so a polygon inside another cuts a hole
  /// (rings: tote handles, neck binding).
  final bool evenOdd;

  /// Ellipses as (centre, radiusX, radiusY); circles use rx == ry.
  final List<(Offset, double, double)> ellipses;

  const ZonePath({
    this.polygons = const [],
    this.ellipses = const [],
    this.evenOdd = false,
  });

  /// The zone outline scaled by [scale] (display size / 1024).
  Path toPath(double scale) {
    final path = Path();
    if (evenOdd) path.fillType = PathFillType.evenOdd;
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

  /// Drawn (vector) garment instead of a photo, for styles without photos.
  final List<VectorPart>? vector;

  const StyleView(this.asset, this.zones) : vector = null;
  const StyleView.vector(List<VectorPart> this.vector)
    : asset = '',
      zones = const {};
}

/// A garment style (crew tee, pocket tee, henley, polo...): its views and the
/// parts that can be coloured.
class GarmentStyle {
  final String id;
  final String label;
  final String description;
  final List<ColorZone> zones;
  final Map<DesignSide, StyleView> views;

  /// Garment category this style belongs to ('tshirt', 'hoodie', 'cap', 'totebag').
  final String garment;

  /// Part colours applied when the style is picked (contrast sleeves, ringer trim...).
  final Map<String, String> defaultParts;

  const GarmentStyle({
    required this.id,
    required this.label,
    required this.description,
    required this.zones,
    required this.views,
    this.garment = 'tshirt',
    this.defaultParts = const {},
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
const _neckTrim = ColorZone('collar', 'Neck trim');
const _armholes = ColorZone('cuffs', 'Armhole trim');
const _hood = ColorZone('hood', 'Hood', trim: false);
const _waistband = ColorZone('waistband', 'Waistband');
const _hoodiePocket = ColorZone('pockets', 'Pocket', trim: false);
const _drawstrings = ColorZone('drawstrings', 'Drawstrings');
const _brim = ColorZone('brim', 'Brim', trim: false);
const _capButton = ColorZone('button', 'Button');
const _strap = ColorZone('strap', 'Strap', trim: false);
const _handles = ColorZone('handles', 'Handles', trim: false);
const _hem = ColorZone('hem', 'Top hem');

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

// ── Zones for the later photo styles (1024-space, see tools/) ───────────────

List<Offset> _m(List<Offset> p, double sum) => [
  for (final o in p) Offset(sum - o.dx, o.dy),
];

/// Left sleeve/cuff polygons mirrored into a right-hand pair.
ZonePath _pair(List<Offset> left, double sum) =>
    ZonePath(polygons: [left, _m(left, sum)]);

final _vneckSleeveL = [
  _o(215, 100),
  _o(150, 135),
  _o(99, 385),
  _o(112, 400),
  _o(256, 430),
  _o(258, 330),
  _o(250, 230),
  _o(235, 150),
];
final _vneckCuffL = [_o(96, 372), _o(256, 408), _o(256, 438), _o(104, 404)];

final _vneckFront = <String, ZonePath>{
  'sleeves': _pair(_vneckSleeveL, 1024),
  'cuffs': _pair(_vneckCuffL, 1024),
  'collar': ZonePath(
    polygons: [
      [
        _o(380, 40),
        _o(504, 240),
        _o(660, 40),
        _o(625, 40),
        _o(504, 205),
        _o(425, 40),
      ],
      [_o(385, 25), _o(645, 25), _o(655, 48), _o(380, 48)],
    ],
  ),
};
final _vneckBack = <String, ZonePath>{
  'sleeves': _pair(_vneckSleeveL, 1024),
  'cuffs': _pair(_vneckCuffL, 1024),
  'collar': ZonePath(
    polygons: [
      [_o(392, 30), _o(640, 30), _o(645, 60), _o(512, 78), _o(395, 60)],
    ],
  ),
};

final _longSleeveL = [
  _o(225, 115),
  _o(190, 150),
  _o(135, 330),
  _o(96, 800),
  _o(94, 935),
  _o(205, 945),
  _o(205, 860),
  _o(240, 560),
  _o(262, 420),
  _o(262, 330),
  _o(250, 200),
];
final _longCuffL = [_o(94, 915), _o(208, 925), _o(205, 980), _o(92, 972)];

final _longFront = <String, ZonePath>{
  'sleeves': _pair(_longSleeveL, 1030),
  'cuffs': _pair(_longCuffL, 1030),
  'collar': ZonePath(ellipses: [(_o(490, 82), 140, 52)]),
};
final _longBack = <String, ZonePath>{
  'sleeves': _pair(_longSleeveL, 1030),
  'cuffs': _pair(_longCuffL, 1030),
  'collar': ZonePath(
    polygons: [
      [_o(392, 32), _o(664, 32), _o(668, 60), _o(530, 80), _o(390, 60)],
    ],
  ),
};

final _raglanL = [
  _o(368, 45),
  _o(260, 95),
  _o(200, 140),
  _o(130, 330),
  _o(88, 690),
  _o(96, 720),
  _o(205, 715),
  _o(215, 690),
  _o(252, 500),
  _o(272, 395),
  _o(285, 360),
  _o(300, 300),
  _o(330, 190),
  _o(360, 100),
];
final _raglanCuffL = [_o(84, 672), _o(212, 690), _o(206, 722), _o(96, 726)];
final _raglanFront = <String, ZonePath>{
  'sleeves': _pair(_raglanL, 1024),
  'cuffs': _pair(_raglanCuffL, 1024),
  'collar': ZonePath(ellipses: [(_o(504, 70), 128, 48)]),
};

final _ringerSleeveL = [
  _o(215, 110),
  _o(190, 140),
  _o(96, 372),
  _o(110, 396),
  _o(264, 448),
  _o(268, 380),
  _o(262, 260),
  _o(245, 170),
];
final _ringerCuffL = [_o(92, 365), _o(266, 414), _o(264, 450), _o(106, 400)];
final _ringerBack = <String, ZonePath>{
  'sleeves': _pair(_ringerSleeveL, 1024),
  'cuffs': _pair(_ringerCuffL, 1024),
  'collar': ZonePath(
    polygons: [
      [_o(350, 32), _o(620, 32), _o(630, 62), _o(485, 82), _o(345, 62)],
    ],
  ),
};

final _tankArmholeL = [
  _o(285, 50),
  _o(305, 50),
  _o(300, 200),
  _o(290, 300),
  _o(300, 410),
  _o(268, 415),
  _o(274, 300),
  _o(282, 200),
];
final _tankFront = <String, ZonePath>{
  'cuffs': _pair(_tankArmholeL, 1020),
  'collar': ZonePath(
    ellipses: [(_o(525, 130), 148, 118), (_o(525, 125), 118, 92)],
    evenOdd: true,
  ),
};
final _tankBack = <String, ZonePath>{
  'cuffs': _pair(_tankArmholeL, 1020),
  'collar': ZonePath(
    polygons: [
      [
        _o(384, 38),
        _o(430, 70),
        _o(512, 98),
        _o(600, 70),
        _o(645, 38),
        _o(660, 45),
        _o(615, 95),
        _o(512, 118),
        _o(410, 95),
        _o(370, 45),
      ],
    ],
  ),
};

final _hoodieSleeveL = [
  _o(260, 240),
  _o(205, 275),
  _o(150, 420),
  _o(120, 700),
  _o(105, 880),
  _o(190, 900),
  _o(215, 750),
  _o(255, 580),
  _o(290, 480),
  _o(300, 330),
  _o(285, 260),
];
final _hoodieCuffL = [_o(120, 885), _o(232, 895), _o(228, 980), _o(130, 985)];
final _hoodieFront = <String, ZonePath>{
  'hood': ZonePath(
    polygons: [
      [
        _o(330, 175),
        _o(335, 100),
        _o(400, 45),
        _o(490, 32),
        _o(580, 45),
        _o(650, 95),
        _o(680, 175),
        _o(640, 200),
        _o(590, 150),
        _o(512, 118),
        _o(430, 150),
        _o(375, 205),
      ],
    ],
  ),
  'sleeves': _pair(_hoodieSleeveL, 1016),
  'cuffs': _pair(_hoodieCuffL, 1016),
  'waistband': ZonePath(
    polygons: [
      [_o(288, 875), _o(800, 875), _o(802, 955), _o(286, 955)],
    ],
  ),
  'pockets': ZonePath(
    polygons: [
      [
        _o(358, 650),
        _o(662, 650),
        _o(712, 790),
        _o(700, 872),
        _o(320, 872),
        _o(310, 790),
      ],
    ],
  ),
  'drawstrings': ZonePath(
    polygons: [
      [_o(448, 200), _o(466, 200), _o(500, 430), _o(484, 430)],
      [_o(530, 200), _o(548, 200), _o(560, 430), _o(544, 430)],
    ],
  ),
};
final _hoodieBackSleeveL = [
  _o(225, 250),
  _o(195, 290),
  _o(150, 430),
  _o(125, 700),
  _o(110, 900),
  _o(190, 910),
  _o(212, 760),
  _o(250, 600),
  _o(285, 500),
  _o(298, 380),
  _o(285, 290),
];
final _hoodieBackCuffL = [
  _o(125, 890),
  _o(238, 900),
  _o(232, 985),
  _o(133, 988),
];
final _hoodieBack = <String, ZonePath>{
  'hood': ZonePath(
    polygons: [
      [
        _o(340, 200),
        _o(350, 70),
        _o(390, 40),
        _o(470, 30),
        _o(580, 35),
        _o(640, 60),
        _o(660, 130),
        _o(650, 260),
        _o(580, 300),
        _o(512, 290),
        _o(450, 300),
        _o(380, 270),
      ],
    ],
  ),
  'sleeves': _pair(_hoodieBackSleeveL, 1020),
  'cuffs': _pair(_hoodieBackCuffL, 1020),
  'waistband': ZonePath(
    polygons: [
      [_o(300, 875), _o(820, 875), _o(826, 960), _o(298, 960)],
    ],
  ),
};

final _capFront = <String, ZonePath>{
  'brim': ZonePath(
    polygons: [
      [
        _o(64, 690),
        _o(280, 665),
        _o(512, 656),
        _o(740, 665),
        _o(992, 690),
        _o(960, 860),
        _o(944, 935),
        _o(780, 895),
        _o(512, 860),
        _o(244, 895),
        _o(80, 935),
        _o(64, 860),
      ],
    ],
  ),
  'button': ZonePath(ellipses: [(_o(512, 86), 30, 22)]),
};
final _capBack = <String, ZonePath>{
  'strap': ZonePath(
    polygons: [
      [_o(280, 660), _o(780, 665), _o(800, 700), _o(790, 745), _o(280, 740)],
    ],
  ),
  'button': ZonePath(ellipses: [(_o(512, 86), 30, 22)]),
};

final _toteHandles = ZonePath(
  polygons: [
    [
      _o(355, 385),
      _o(365, 260),
      _o(390, 150),
      _o(440, 70),
      _o(510, 38),
      _o(585, 70),
      _o(630, 150),
      _o(655, 260),
      _o(665, 385),
    ],
    [
      _o(435, 385),
      _o(440, 260),
      _o(455, 170),
      _o(490, 110),
      _o(520, 90),
      _o(555, 110),
      _o(585, 170),
      _o(598, 260),
      _o(600, 385),
    ],
  ],
  evenOdd: true,
);
final _toteZones = <String, ZonePath>{
  'handles': _toteHandles,
  'hem': ZonePath(
    polygons: [
      [_o(232, 382), _o(780, 382), _o(785, 425), _o(228, 425)],
    ],
  ),
};

const _dir = 'assets/images/garments';

// ── Raglan back, ringer front, side views ───────────────────────────────────

final _raglanBack = <String, ZonePath>{
  'sleeves': _pair(_raglanL, 1024),
  'cuffs': _pair(_raglanCuffL, 1024),
  'collar': ZonePath(
    polygons: [
      [_o(376, 30), _o(632, 30), _o(640, 58), _o(512, 70), _o(372, 58)],
    ],
  ),
};

final _ringerSleeveFrontL = [
  _o(215, 110),
  _o(190, 140),
  _o(83, 400),
  _o(100, 425),
  _o(256, 468),
  _o(262, 380),
  _o(255, 260),
  _o(240, 170),
];
final _ringerCuffFrontL = [
  _o(80, 385),
  _o(258, 440),
  _o(256, 478),
  _o(98, 420),
];
final _ringerFront = <String, ZonePath>{
  'sleeves': _pair(_ringerSleeveFrontL, 1027),
  'cuffs': _pair(_ringerCuffFrontL, 1027),
  'collar': ZonePath(ellipses: [(_o(508, 92), 130, 58)]),
};

// Side views: the visible sleeve and its hem, as seen from the wearer's left
// (photos face left) and right (mirrored geometry).
final _crewSleeveL = [
  _o(455, 140),
  _o(520, 115),
  _o(600, 130),
  _o(650, 185),
  _o(645, 300),
  _o(640, 405),
  _o(600, 450),
  _o(533, 462),
  _o(470, 450),
  _o(437, 420),
  _o(430, 300),
  _o(440, 200),
];
final _crewSideCuffL = [
  _o(437, 415),
  _o(470, 395),
  _o(533, 388),
  _o(600, 395),
  _o(640, 405),
  _o(640, 440),
  _o(600, 458),
  _o(533, 462),
  _o(470, 455),
  _o(437, 440),
];
final _poloSleeveL = [
  _o(490, 160),
  _o(545, 130),
  _o(610, 150),
  _o(625, 300),
  _o(622, 420),
  _o(560, 470),
  _o(500, 480),
  _o(462, 440),
  _o(465, 300),
];
final _poloSideCuffL = [
  _o(462, 410),
  _o(560, 395),
  _o(622, 415),
  _o(622, 470),
  _o(560, 485),
  _o(500, 480),
  _o(460, 450),
];

Map<String, ZonePath> _side(
  List<Offset> sleeve,
  List<Offset> cuff, {
  bool mirror = false,
  double sum = 1045,
}) => {
  'sleeves': ZonePath(polygons: [mirror ? _m(sleeve, sum) : sleeve]),
  'cuffs': ZonePath(polygons: [mirror ? _m(cuff, sum) : cuff]),
};

Map<DesignSide, StyleView> _crewSides() => {
  DesignSide.left: StyleView(
    '$_dir/crew_left.png',
    _side(_crewSleeveL, _crewSideCuffL),
  ),
  DesignSide.right: StyleView(
    '$_dir/crew_right.png',
    _side(_crewSleeveL, _crewSideCuffL, mirror: true),
  ),
};
Map<DesignSide, StyleView> _poloSides() => {
  DesignSide.left: StyleView(
    '$_dir/polo_left.png',
    _side(_poloSleeveL, _poloSideCuffL),
  ),
  DesignSide.right: StyleView(
    '$_dir/polo_right.png',
    _side(_poloSleeveL, _poloSideCuffL, mirror: true, sum: 1066),
  ),
};

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
        ..._crewSides(),
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
        ..._crewSides(),
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
        ..._crewSides(),
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
        ..._crewSides(),
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
        ..._crewSides(),
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
        ..._poloSides(),
      },
    ),
    GarmentStyle(
      id: 'vneck',
      label: 'V-neck',
      description: 'V-shaped neckline',
      zones: const [_sleeves, _cuffs, _collar],
      views: {
        DesignSide.front: StyleView('$_dir/vneck_front.png', _vneckFront),
        DesignSide.back: StyleView('$_dir/vneck_back.png', _vneckBack),
        ..._crewSides(),
      },
    ),
    GarmentStyle(
      id: 'longsleeve',
      label: 'Long sleeve',
      description: 'Full-length sleeves with cuffs',
      zones: const [_sleeves, _cuffs, _collar],
      views: {
        DesignSide.front: StyleView('$_dir/longsleeve_front.png', _longFront),
        DesignSide.back: StyleView('$_dir/longsleeve_back.png', _longBack),
      },
    ),
    GarmentStyle(
      id: 'raglan',
      label: 'Raglan',
      description: '3/4 baseball sleeves, contrast by default',
      defaultParts: const {'sleeves': '0xFF2B2E33'},
      zones: const [_sleeves, _cuffs, _collar],
      views: {
        DesignSide.front: StyleView('$_dir/raglan_front.png', _raglanFront),
        DesignSide.back: StyleView('$_dir/raglan_back.png', _raglanBack),
      },
    ),
    GarmentStyle(
      id: 'ringer',
      label: 'Ringer',
      description: 'Contrast collar and cuffs',
      defaultParts: const {'collar': '0xFF1A1F3C', 'cuffs': '0xFF1A1F3C'},
      zones: const [_sleeves, _cuffs, _collar],
      views: {
        DesignSide.front: StyleView('$_dir/ringer_front.png', _ringerFront),
        DesignSide.back: StyleView('$_dir/ringer_back.png', _ringerBack),
      },
    ),
    GarmentStyle(
      id: 'tank',
      label: 'Tank top',
      description: 'Sleeveless with bound edges',
      zones: const [_armholes, _neckTrim],
      views: {
        DesignSide.front: StyleView('$_dir/tank_front.png', _tankFront),
        DesignSide.back: StyleView('$_dir/tank_back.png', _tankBack),
      },
    ),
    GarmentStyle(
      id: 'hoodie',
      label: 'Hoodie',
      description: 'Pullover with hood and pocket',
      garment: 'hoodie',
      zones: const [
        _hood,
        _sleeves,
        _cuffs,
        _waistband,
        _hoodiePocket,
        _drawstrings,
      ],
      views: {
        DesignSide.front: StyleView('$_dir/hoodie_front.png', _hoodieFront),
        DesignSide.back: StyleView('$_dir/hoodie_back.png', _hoodieBack),
      },
    ),
    GarmentStyle(
      id: 'cap',
      label: 'Cap',
      description: 'Baseball cap',
      garment: 'cap',
      zones: const [_brim, _capButton, _strap],
      views: {
        DesignSide.front: StyleView('$_dir/cap_front.png', _capFront),
        DesignSide.back: StyleView('$_dir/cap_back.png', _capBack),
      },
    ),
    GarmentStyle(
      id: 'tote',
      label: 'Tote bag',
      description: 'Canvas tote with handles',
      garment: 'totebag',
      zones: const [_handles, _hem],
      views: {
        DesignSide.front: StyleView('$_dir/tote_front.png', _toteZones),
        DesignSide.back: StyleView('$_dir/tote_back.png', _toteZones),
      },
    ),
  ];

  /// Styles offered for a garment category ('tshirt', 'hoodie', ...).
  static List<GarmentStyle> forGarment(String garment) =>
      all.where((s) => s.garment == garment).toList();

  /// The style to draw for [garment]: [styleId] if it belongs there, else the
  /// garment's first style; null when the garment has none.
  static GarmentStyle? resolve(String garment, String? styleId) {
    // The business's separate "Polo Shirt" garment is just the polo style.
    if (garment == 'polo') return byId('polo');
    final list = forGarment(garment);
    if (list.isEmpty) return null;
    return list.firstWhere((s) => s.id == styleId, orElse: () => list.first);
  }

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
