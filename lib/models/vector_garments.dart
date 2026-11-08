import 'dart:typed_data';
import 'dart:ui';

import 'garment_style.dart';

/// One drawn piece of a vector garment, in the 1024×1024 style space.
class VectorPart {
  /// 'body' (garment colour), a [ColorZone] id, or 'detail' (fixed [shade]).
  final String zone;
  final Path path;

  /// Null fills the path; otherwise the path is stroked with this width,
  /// clipped to the garment so trims stay inside the silhouette.
  final double? stroke;

  /// For 'detail' parts: black at this opacity (stitching, hood shadow).
  final double shade;

  const VectorPart(this.zone, this.path, {this.stroke, this.shade = 0});
}

Path _mirror(Path p) => p.transform(
  Float64List.fromList([-1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 1024, 0, 0, 1]),
);

Path _both(Path left) => Path()
  ..addPath(left, Offset.zero)
  ..addPath(_mirror(left), Offset.zero);

Offset _lerpToward(Offset from, Offset to, double dist) {
  final d = to - from;
  return from + d / d.distance * dist;
}

// ── T-shirt family ──────────────────────────────────────────────────────────

Path _neckline(String neck, {required bool back}) {
  const l = Offset(402, 92), r = Offset(622, 92);
  final p = Path()..moveTo(l.dx, l.dy);
  if (back) {
    p.quadraticBezierTo(512, 150, r.dx, r.dy);
  } else if (neck == 'vneck') {
    p
      ..lineTo(512, 310)
      ..lineTo(r.dx, r.dy);
  } else if (neck == 'scoop') {
    p.quadraticBezierTo(512, 400, r.dx, r.dy);
  } else {
    p.quadraticBezierTo(512, 262, r.dx, r.dy);
  }
  return p;
}

Path _teeBody({required String neck, required bool back, double hem = 905}) {
  final p = Path()
    ..moveTo(402, 92)
    ..lineTo(300, 125)
    ..cubicTo(270, 160, 262, 260, 276, 350)
    ..lineTo(284, hem - 5)
    ..quadraticBezierTo(512, hem + 22, 740, hem - 5)
    ..lineTo(748, 350)
    ..cubicTo(762, 260, 754, 160, 724, 125)
    ..lineTo(622, 92);
  // Neckline back across to the start.
  if (back) {
    p.quadraticBezierTo(512, 150, 402, 92);
  } else if (neck == 'vneck') {
    p
      ..lineTo(512, 310)
      ..lineTo(402, 92);
  } else if (neck == 'scoop') {
    p.quadraticBezierTo(512, 400, 402, 92);
  } else {
    p.quadraticBezierTo(512, 262, 402, 92);
  }
  return p..close();
}

/// Left sleeve ending at height [e] (338 short, ~620 three-quarter, ~830
/// long). Returns the sleeve and its cuff band.
({Path sleeve, Path cuff}) _sleeve(double e, {required bool raglan}) {
  final t = e - 338;
  final e1 = Offset(98 - t * 0.08, e);
  final e2 = Offset(262 - t * 0.17, e + 47);
  const a = Offset(276, 350);
  final sleeve = Path();
  if (raglan) {
    sleeve
      ..moveTo(402, 95)
      ..lineTo(190, 170);
  } else {
    sleeve
      ..moveTo(300, 125)
      ..lineTo(185, 172);
  }
  sleeve
    ..cubicTo(150, 215, e1.dx + 14, e - 120, e1.dx, e1.dy)
    ..lineTo(e2.dx, e2.dy)
    ..lineTo(a.dx, a.dy);
  if (raglan) {
    sleeve.cubicTo(300, 250, 350, 160, 402, 95);
  }
  sleeve.close();
  final h = e > 500 ? 58.0 : 36.0;
  final u1 = _lerpToward(e1, const Offset(185, 172), h);
  final u2 = _lerpToward(e2, a, h);
  final cuff = Path()
    ..moveTo(e1.dx, e1.dy)
    ..lineTo(e2.dx, e2.dy)
    ..lineTo(u2.dx, u2.dy)
    ..lineTo(u1.dx, u1.dy)
    ..close();
  return (sleeve: sleeve, cuff: cuff);
}

Path _hemStitch(double y) => Path()
  ..moveTo(292, y)
  ..quadraticBezierTo(512, y + 22, 732, y);

List<VectorPart> _tee({
  required String neck,
  required bool back,
  double sleeveEnd = 338,
  bool raglan = false,
}) {
  final s = _sleeve(sleeveEnd, raglan: raglan);
  return [
    VectorPart('body', _teeBody(neck: neck, back: back)),
    VectorPart('sleeves', _both(s.sleeve)),
    VectorPart('cuffs', _both(s.cuff)),
    VectorPart('collar', _neckline(neck, back: back), stroke: 36),
    VectorPart('detail', _hemStitch(868), stroke: 2.5, shade: 0.25),
  ];
}

List<VectorPart> _tank({required bool back}) {
  final body = Path()
    ..moveTo(330, 92)
    ..lineTo(398, 92);
  if (back) {
    body.quadraticBezierTo(512, 170, 626, 92);
  } else {
    body.quadraticBezierTo(512, 360, 626, 92);
  }
  body
    ..lineTo(694, 92)
    ..cubicTo(695, 210, 735, 270, 748, 350)
    ..lineTo(752, 900)
    ..quadraticBezierTo(512, 925, 272, 900)
    ..lineTo(276, 350)
    ..cubicTo(289, 270, 329, 210, 330, 92)
    ..close();
  final binding = Path()
    ..moveTo(330, 92)
    ..cubicTo(329, 210, 289, 270, 276, 350)
    ..moveTo(694, 92)
    ..cubicTo(695, 210, 735, 270, 748, 350);
  final neck = Path()
    ..moveTo(398, 92)
    ..quadraticBezierTo(512, back ? 170 : 360, 626, 92);
  return [
    VectorPart('body', body),
    VectorPart('cuffs', binding, stroke: 30),
    VectorPart('collar', neck, stroke: 30),
    VectorPart('detail', _hemStitch(868), stroke: 2.5, shade: 0.25),
  ];
}

// ── Hoodie ──────────────────────────────────────────────────────────────────

List<VectorPart> _hoodie({required bool back}) {
  final s = _sleeve(830, raglan: false);
  final body = Path()
    ..moveTo(402, 110)
    ..lineTo(292, 140)
    ..cubicTo(260, 175, 252, 270, 268, 350)
    ..lineTo(280, 930)
    ..quadraticBezierTo(512, 950, 744, 930)
    ..lineTo(756, 350)
    ..cubicTo(772, 270, 764, 175, 732, 140)
    ..lineTo(622, 110)
    ..close();
  final hood = Path()
    ..moveTo(385, 125)
    ..cubicTo(350, -10, 674, -10, 639, 125)
    ..quadraticBezierTo(512, back ? 190 : 285, 385, 125)
    ..close();
  final hoodInner = Path()
    ..moveTo(425, 122)
    ..cubicTo(440, 55, 584, 55, 599, 122)
    ..quadraticBezierTo(512, back ? 160 : 235, 425, 122)
    ..close();
  final waist = Path()
    ..moveTo(281, 880)
    ..lineTo(743, 880)
    ..lineTo(744, 935)
    ..lineTo(280, 935)
    ..close();
  final pocket = Path()
    ..moveTo(335, 640)
    ..lineTo(689, 640)
    ..lineTo(716, 800)
    ..lineTo(308, 800)
    ..close();
  final pocketSeams = Path()
    ..moveTo(380, 640)
    ..lineTo(352, 770)
    ..moveTo(644, 640)
    ..lineTo(672, 770);
  final strings = Path()
    ..moveTo(470, 232)
    ..lineTo(466, 360)
    ..moveTo(554, 232)
    ..lineTo(558, 360);
  return [
    VectorPart('body', body),
    VectorPart('sleeves', _both(s.sleeve)),
    VectorPart('cuffs', _both(s.cuff)),
    VectorPart('waistband', waist),
    if (!back) ...[
      VectorPart('pockets', pocket),
      VectorPart('detail', pocketSeams, stroke: 2.5, shade: 0.28),
    ],
    VectorPart('hood', hood),
    VectorPart('detail', hoodInner, shade: 0.22),
    if (!back) VectorPart('drawstrings', strings, stroke: 9),
  ];
}

// ── Cap ─────────────────────────────────────────────────────────────────────

List<VectorPart> _cap({required bool back}) {
  final crown = Path()
    ..moveTo(200, 575)
    ..cubicTo(200, 190, 824, 190, 824, 575)
    ..close();
  final seams = Path()
    ..moveTo(512, 290)
    ..cubicTo(500, 380, 500, 470, 512, 565)
    ..moveTo(372, 310)
    ..cubicTo(330, 390, 322, 470, 340, 565)
    ..moveTo(652, 310)
    ..cubicTo(694, 390, 702, 470, 684, 565);
  if (back) {
    final strap = Path()
      ..moveTo(232, 520)
      ..lineTo(792, 520)
      ..lineTo(800, 580)
      ..lineTo(224, 580)
      ..close();
    return [
      VectorPart('body', crown),
      VectorPart('detail', seams, stroke: 2.5, shade: 0.22),
      VectorPart('strap', strap),
    ];
  }
  final brim = Path()
    ..moveTo(176, 545)
    ..cubicTo(250, 800, 774, 800, 848, 545)
    ..cubicTo(700, 600, 324, 600, 176, 545)
    ..close();
  final button = Path()
    ..addOval(Rect.fromCircle(center: const Offset(512, 288), radius: 16));
  return [
    VectorPart('body', crown),
    VectorPart('detail', seams, stroke: 2.5, shade: 0.22),
    VectorPart('brim', brim),
    VectorPart('button', button),
  ];
}

// ── Tote bag ────────────────────────────────────────────────────────────────

List<VectorPart> _tote() {
  final body = Path()
    ..moveTo(210, 330)
    ..lineTo(814, 330)
    ..lineTo(850, 900)
    ..lineTo(174, 900)
    ..close();
  final hem = Path()
    ..moveTo(210, 330)
    ..lineTo(814, 330)
    ..lineTo(818, 385)
    ..lineTo(206, 385)
    ..close();
  final handles = Path()
    ..moveTo(340, 340)
    ..cubicTo(330, 90, 694, 90, 684, 340);
  return [
    VectorPart('handles', handles, stroke: 38),
    VectorPart('body', body),
    VectorPart('hem', hem),
    VectorPart('detail', _hemStitch(870), stroke: 2.5, shade: 0.25),
  ];
}

/// Vector views per style id (front, back).
class VectorGarments {
  VectorGarments._();

  static final Map<String, ({List<VectorPart> front, List<VectorPart> back})>
  _byStyle = {
    'vneck': (
      front: _tee(neck: 'vneck', back: false),
      back: _tee(neck: 'crew', back: true),
    ),
    'longsleeve': (
      front: _tee(neck: 'crew', back: false, sleeveEnd: 830),
      back: _tee(neck: 'crew', back: true, sleeveEnd: 830),
    ),
    'raglan': (
      front: _tee(neck: 'crew', back: false, sleeveEnd: 620, raglan: true),
      back: _tee(neck: 'crew', back: true, sleeveEnd: 620, raglan: true),
    ),
    'ringer': (
      front: _tee(neck: 'crew', back: false),
      back: _tee(neck: 'crew', back: true),
    ),
    'tank': (front: _tank(back: false), back: _tank(back: true)),
    'hoodie': (front: _hoodie(back: false), back: _hoodie(back: true)),
    'cap': (front: _cap(back: false), back: _cap(back: true)),
    'tote': (front: _tote(), back: _tote()),
  };

  static List<VectorPart>? front(String id) => _byStyle[id]?.front;
  static List<VectorPart>? back(String id) => _byStyle[id]?.back;

  /// Silhouette used to clip trims and shading: all filled, non-detail parts.
  static Path silhouette(List<VectorPart> parts) {
    var out = Path();
    for (final p in parts) {
      if (p.stroke != null || p.zone == 'detail') continue;
      out = Path.combine(PathOperation.union, out, p.path);
    }
    return out;
  }
}
