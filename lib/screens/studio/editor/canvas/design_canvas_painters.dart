import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:designwear/models/models.dart' show VectorPart, VectorGarments;

class CanvasGridPainter extends CustomPainter {
  final Color color;
  const CanvasGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    const spacing = 24.0;
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CanvasGridPainter old) => old.color != color;
}

/// Draws marigold dashed centre lines while an element snaps to centre.
class SnapGuidePainter extends CustomPainter {
  final bool vertical;
  final bool horizontal;
  final Color color;

  const SnapGuidePainter({
    required this.vertical,
    required this.horizontal,
    required this.color,
  });

  void _dashedLine(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0, gap = 4.0;
    final total = (b - a).distance;
    final dir = (b - a) / total;
    double drawn = 0;
    while (drawn < total) {
      final start = a + dir * drawn;
      final end = a + dir * math.min(drawn + dash, total);
      canvas.drawLine(start, end, paint);
      drawn += dash + gap;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    if (vertical) {
      _dashedLine(
        canvas,
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );
    }
    if (horizontal) {
      _dashedLine(
        canvas,
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(SnapGuidePainter old) =>
      old.vertical != vertical ||
      old.horizontal != horizontal ||
      old.color != color;
}

/// Draws collar, pocket, sleeve-cuff and fabric-finish overlays on the t-shirt.
/// Coordinates calibrated for the retired tshirt_white.png photo (now unused: styles draw from assets/images/garments).
class GarmentOverlayPainter extends CustomPainter {
  final Color tshirtColor;
  final String collarStyle; // 'crew' | 'vneck' | 'polo'
  final String pocketStyle; // 'none' | 'left' | 'right' | 'both'

  /// Explicit accent colour for collar/pocket/cuff trim. When null the trim
  /// auto-derives a contrasting shade from [tshirtColor] (legacy behaviour).
  final Color? trimColor;

  /// Per-area overrides; each falls back to [trimColor], then to the derived shade.
  final Color? collarColor;
  final Color? pocketColor;
  final Color? cuffColor;
  final String sleeveCuff; // 'none' | 'banded' | 'rolled'
  final String fabricFinish; // 'solid' | 'heather' | 'vintage'

  const GarmentOverlayPainter({
    required this.tshirtColor,
    required this.collarStyle,
    required this.pocketStyle,
    this.trimColor,
    this.collarColor,
    this.pocketColor,
    this.cuffColor,
    this.sleeveCuff = 'none',
    this.fabricFinish = 'solid',
  });

  static const double _cx = 166.0;
  static const double _collarTopY = 80.0;
  static const double _collarMidY = 126.0;
  static const double _collarHalfW = 46.0;
  static const double _pocketW = 44.0;
  static const double _pocketH = 40.0;
  static const double _pocketTopY = 168.0;
  static const double _leftPocketCX = 108.0;
  static const double _rightPocketCX = 224.0;

  // Sleeve-hem endpoints (cuff sits just above the short-sleeve hem).
  static const Offset _leftCuffOuter = Offset(52, 188);
  static const Offset _leftCuffInner = Offset(96, 174);
  static const Offset _rightCuffOuter = Offset(280, 188);
  static const Offset _rightCuffInner = Offset(236, 174);

  Color? get _collarTrim => collarColor ?? trimColor;
  Color? get _pocketTrim => pocketColor ?? trimColor;
  Color? get _cuffTrim => cuffColor ?? trimColor;

  @override
  void paint(Canvas canvas, Size size) {
    // Finish goes first so trims/overlays sit on top of the texture.
    _paintFinish(canvas);
    _paintCollar(canvas);
    _paintPockets(canvas);
    _paintCuffs(canvas);
  }

  // ── Collar ──────────────────────────────────────────────────────────────────

  void _paintCollar(Canvas canvas) {
    if (collarStyle == 'crew') return;

    final fillColor = _collarTrim != null
        ? _collarTrim!
        : _adjust(tshirtColor, 0.14);
    final borderColor = _collarTrim != null
        ? _adjust(_collarTrim!, 0.32)
        : _adjust(tshirtColor, 0.32);
    final fill = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    if (collarStyle == 'vneck') {
      final path = Path()
        ..moveTo(_cx - _collarHalfW, _collarTopY)
        ..lineTo(_cx, _collarMidY)
        ..lineTo(_cx + _collarHalfW, _collarTopY)
        ..close();
      canvas.drawPath(path, fill);
      canvas.drawPath(path, border);
    } else if (collarStyle == 'polo') {
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          _cx - _collarHalfW - 6,
          _collarTopY,
          (_collarHalfW + 6) * 2,
          42,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, border);
      final line = Paint()
        ..color = borderColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(_cx, _collarTopY + 6),
        Offset(_cx, _collarTopY + 40),
        line,
      );
      final btn = Paint()
        ..color = _adjust(
          _collarTrim != null ? _collarTrim! : tshirtColor,
          0.42,
        )
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(_cx, _collarTopY + 16), 3.5, btn);
      canvas.drawCircle(Offset(_cx, _collarTopY + 30), 3.5, btn);
    }
  }

  // ── Pockets ─────────────────────────────────────────────────────────────────

  void _paintPockets(Canvas canvas) {
    if (pocketStyle == 'none') return;

    final fill = Paint()
      ..color = _pocketTrim != null ? _pocketTrim! : _adjust(tshirtColor, 0.13)
      ..style = PaintingStyle.fill;
    final stitch = Paint()
      ..color = _pocketTrim != null
          ? _adjust(_pocketTrim!, 0.30)
          : _adjust(tshirtColor, 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round;

    void drawPocket(double cx) {
      final rect = Rect.fromLTWH(
        cx - _pocketW / 2,
        _pocketTopY,
        _pocketW,
        _pocketH,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        fill,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(2)),
        stitch,
      );
    }

    if (pocketStyle == 'left' || pocketStyle == 'both') {
      drawPocket(_rightPocketCX);
    }
    if (pocketStyle == 'right' || pocketStyle == 'both') {
      drawPocket(_leftPocketCX);
    }
  }

  // ── Sleeve cuffs ─────────────────────────────────────────────────────────────

  void _paintCuffs(Canvas canvas) {
    if (sleeveCuff == 'none') return;

    final bandColor = _cuffTrim != null
        ? _cuffTrim!
        : _adjust(tshirtColor, 0.16);
    final edgeColor = _adjust(bandColor, 0.30);

    void drawCuff(Offset outer, Offset inner) {
      if (sleeveCuff == 'rolled') {
        // Two stacked folds for a rolled-up look.
        for (final shift in const [0.0, -7.0]) {
          final o = Offset(outer.dx, outer.dy + shift);
          final i = Offset(inner.dx, inner.dy + shift);
          canvas.drawLine(
            o,
            i,
            Paint()
              ..color = bandColor
              ..strokeWidth = 5
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawLine(
          outer,
          inner,
          Paint()
            ..color = edgeColor
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round,
        );
      } else {
        // 'banded' — a single accent band.
        canvas.drawLine(
          outer,
          inner,
          Paint()
            ..color = bandColor
            ..strokeWidth = 8
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawLine(
          Offset(outer.dx, outer.dy - 4.5),
          Offset(inner.dx, inner.dy - 4.5),
          Paint()
            ..color = edgeColor
            ..strokeWidth = 1.0
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    drawCuff(_leftCuffOuter, _leftCuffInner);
    drawCuff(_rightCuffOuter, _rightCuffInner);
  }

  // ── Fabric finish ────────────────────────────────────────────────────────────

  void _paintFinish(Canvas canvas) {
    if (fabricFinish == 'solid') return;

    // Torso region kept safely inside the shirt silhouette.
    final torso = Rect.fromLTRB(72, 110, 260, 360);
    canvas.save();
    canvas.clipRect(torso);

    final lighten = tshirtColor.computeLuminance() < 0.25;

    if (fabricFinish == 'heather') {
      // Marl texture: many tiny deterministic flecks, half light / half dark.
      final rng = math.Random(7);
      final light = Paint()..color = Colors.white.withValues(alpha: 0.05);
      final dark = Paint()..color = Colors.black.withValues(alpha: 0.05);
      for (int i = 0; i < 220; i++) {
        final dx = torso.left + rng.nextDouble() * torso.width;
        final dy = torso.top + rng.nextDouble() * torso.height;
        final r = 0.6 + rng.nextDouble() * 1.1;
        canvas.drawCircle(Offset(dx, dy), r, i.isEven ? light : dark);
      }
    } else if (fabricFinish == 'vintage') {
      // Faded centre highlight + softly darkened edges for a washed look.
      final center = torso.center;
      final wash = Paint()
        ..shader =
            RadialGradient(
              colors: [
                (lighten ? Colors.white : Colors.white).withValues(alpha: 0.12),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromCircle(center: center, radius: torso.width * 0.7),
            );
      canvas.drawRect(torso, wash);

      final vignette = Paint()
        ..shader =
            RadialGradient(
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.08),
              ],
              stops: const [0.6, 1.0],
            ).createShader(
              Rect.fromCircle(center: center, radius: torso.width * 0.8),
            );
      canvas.drawRect(torso, vignette);
    }

    canvas.restore();
  }

  static int _channel(double v) => (v * 255.0).round().clamp(0, 255);

  Color _adjust(Color color, double amount) {
    if (color.computeLuminance() < 0.25) {
      return Color.fromARGB(
        _channel(color.a),
        (_channel(color.r) + (255 - _channel(color.r)) * amount).round().clamp(
          0,
          255,
        ),
        (_channel(color.g) + (255 - _channel(color.g)) * amount).round().clamp(
          0,
          255,
        ),
        (_channel(color.b) + (255 - _channel(color.b)) * amount).round().clamp(
          0,
          255,
        ),
      );
    }
    return Color.fromARGB(
      _channel(color.a),
      (_channel(color.r) * (1 - amount)).round().clamp(0, 255),
      (_channel(color.g) * (1 - amount)).round().clamp(0, 255),
      (_channel(color.b) * (1 - amount)).round().clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(GarmentOverlayPainter old) =>
      old.tshirtColor != tshirtColor ||
      old.collarStyle != collarStyle ||
      old.pocketStyle != pocketStyle ||
      old.trimColor != trimColor ||
      old.collarColor != collarColor ||
      old.pocketColor != pocketColor ||
      old.cuffColor != cuffColor ||
      old.sleeveCuff != sleeveCuff ||
      old.fabricFinish != fabricFinish;
}

/// A T-shirt sleeve seen from the side, for the Left / Right views. The shirt
/// photos only exist for front and back, so sleeves are drawn: fabric in the
/// garment colour, a shoulder seam, a hem band at the cuff, and a dashed box
/// marking the print area.
class SleevePainter extends CustomPainter {
  SleevePainter({
    required this.color,
    required this.mirrored,
    this.showGuide = true,
  });

  final Color color;

  /// True for the right sleeve: the same shape flipped, so the shoulder seam
  /// is on the other side.
  final bool mirrored;
  final bool showGuide;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    if (mirrored) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }
    double x(double v) => v * size.width;
    double y(double v) => v * size.height;

    // Sleeve outline: wide at the shoulder (top), narrowing to the cuff.
    final sleeve = Path()
      ..moveTo(x(0.20), y(0.06))
      ..quadraticBezierTo(x(0.50), y(0.00), x(0.84), y(0.10))
      ..lineTo(x(0.78), y(0.84))
      ..quadraticBezierTo(x(0.52), y(0.90), x(0.26), y(0.84))
      ..close();

    canvas.drawShadow(sleeve, Colors.black, 8, false);
    canvas.drawPath(sleeve, Paint()..color = color);

    // Light-to-dark fabric shading across the sleeve.
    canvas.drawPath(
      sleeve,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
          ],
        ).createShader(Offset.zero & size),
    );

    // Hem band at the cuff.
    final hem = Path()
      ..moveTo(x(0.26), y(0.74))
      ..quadraticBezierTo(x(0.52), y(0.80), x(0.78), y(0.74))
      ..lineTo(x(0.78), y(0.84))
      ..quadraticBezierTo(x(0.52), y(0.90), x(0.26), y(0.84))
      ..close();
    canvas.drawPath(hem, Paint()..color = Colors.black.withValues(alpha: 0.10));

    // Shoulder seam (the side that joins the body).
    canvas.drawLine(
      Offset(x(0.24), y(0.07)),
      Offset(x(0.27), y(0.80)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.16)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke,
    );

    canvas.drawPath(
      sleeve,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.black26,
    );
    canvas.restore();

    if (showGuide) {
      // Print area, drawn un-mirrored so it stays centred.
      final guide = Rect.fromLTWH(x(0.34), y(0.22), x(0.34), y(0.40));
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      const dash = 6.0;
      void edge(Offset a, Offset b) {
        final total = (b - a).distance;
        final dir = (b - a) / total;
        for (double d = 0; d < total; d += dash * 2) {
          canvas.drawLine(
            a + dir * d,
            a + dir * (d + dash).clamp(0, total).toDouble(),
            paint,
          );
        }
      }

      edge(guide.topLeft, guide.topRight);
      edge(guide.topRight, guide.bottomRight);
      edge(guide.bottomRight, guide.bottomLeft);
      edge(guide.bottomLeft, guide.topLeft);
    }
  }

  @override
  bool shouldRepaint(SleevePainter old) =>
      old.color != color ||
      old.mirrored != mirrored ||
      old.showGuide != showGuide;
}

/// A close-up of one chest pocket, for the Left / Right Pocket views. The
/// shirt photo is only front/back, so the pocket is drawn: fabric in the
/// garment colour, a pocket patch (in its accent colour, or a derived shade),
/// stitching, and a dashed box marking the small print area on the pocket.
class PocketAreaPainter extends CustomPainter {
  PocketAreaPainter({
    required this.color,
    this.pocketColor,
    this.showGuide = true,
  });

  final Color color;

  /// Explicit pocket colour; null derives a slightly shifted shade of [color].
  final Color? pocketColor;
  final bool showGuide;

  @override
  void paint(Canvas canvas, Size size) {
    double x(double v) => v * size.width;
    double y(double v) => v * size.height;

    final fabric = Rect.fromLTWH(x(0.08), y(0.08), x(0.84), y(0.84));
    canvas.drawShadow(Path()..addRect(fabric), Colors.black, 8, false);
    canvas.drawRect(fabric, Paint()..color = color);
    canvas.drawRect(
      fabric,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.12),
          ],
        ).createShader(fabric),
    );

    final dark = color.computeLuminance() < 0.25;
    final patchColor =
        pocketColor ??
        Color.lerp(color, dark ? Colors.white : Colors.black, 0.10)!;
    final patch = RRect.fromRectAndRadius(
      Rect.fromLTWH(x(0.22), y(0.20), x(0.56), y(0.56)),
      const Radius.circular(6),
    );
    canvas.drawRRect(patch, Paint()..color = patchColor);
    final stitchColor = Color.lerp(
      patchColor,
      patchColor.computeLuminance() < 0.25 ? Colors.white : Colors.black,
      0.30,
    )!;
    canvas.drawRRect(
      patch.deflate(6),
      Paint()
        ..color = stitchColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
    canvas.drawRRect(
      patch,
      Paint()
        ..color = Colors.black26
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    if (showGuide) {
      // Print area, centred on the pocket.
      final guide = Rect.fromLTWH(x(0.30), y(0.30), x(0.40), y(0.38));
      final paint = Paint()
        ..color = Colors.black.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      const dash = 6.0;
      void edge(Offset a, Offset b) {
        final total = (b - a).distance;
        final dir = (b - a) / total;
        for (double d = 0; d < total; d += dash * 2) {
          canvas.drawLine(
            a + dir * d,
            a + dir * (d + dash).clamp(0, total).toDouble(),
            paint,
          );
        }
      }

      edge(guide.topLeft, guide.topRight);
      edge(guide.topRight, guide.bottomRight);
      edge(guide.bottomRight, guide.bottomLeft);
      edge(guide.bottomLeft, guide.topLeft);
    }
  }

  @override
  bool shouldRepaint(PocketAreaPainter old) =>
      old.color != color ||
      old.pocketColor != pocketColor ||
      old.showGuide != showGuide;
}

/// Fabric finish (heather / vintage) laid over the torso of a style photo.
/// [size] is the square the 1024-unit garment photo is drawn into.
class FabricFinishPainter extends CustomPainter {
  final Color garmentColor;
  final String finish; // 'solid' | 'heather' | 'vintage'
  const FabricFinishPainter({required this.garmentColor, required this.finish});

  @override
  void paint(Canvas canvas, Size size) {
    if (finish == 'solid') return;
    final torso = Rect.fromLTRB(
      size.width * 0.30,
      size.height * 0.20,
      size.width * 0.72,
      size.height * 0.88,
    );
    canvas.save();
    canvas.clipRect(torso);
    if (finish == 'heather') {
      final rng = math.Random(7);
      final light = Paint()..color = Colors.white.withValues(alpha: 0.06);
      final dark = Paint()..color = Colors.black.withValues(alpha: 0.06);
      for (int i = 0; i < 260; i++) {
        final dx = torso.left + rng.nextDouble() * torso.width;
        final dy = torso.top + rng.nextDouble() * torso.height;
        canvas.drawCircle(
          Offset(dx, dy),
          0.6 + rng.nextDouble() * 1.1,
          i.isEven ? light : dark,
        );
      }
    } else {
      final center = torso.center;
      canvas.drawRect(
        torso,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ).createShader(
                Rect.fromCircle(center: center, radius: torso.width * 0.7),
              ),
      );
      canvas.drawRect(
        torso,
        Paint()
          ..shader =
              RadialGradient(
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.08),
                ],
                stops: const [0.6, 1.0],
              ).createShader(
                Rect.fromCircle(center: center, radius: torso.width * 0.8),
              ),
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(FabricFinishPainter old) =>
      old.finish != finish || old.garmentColor != garmentColor;
}

/// Draws a vector garment (styles without a photo): each part filled in the
/// garment colour or its own zone colour, trims clipped to the silhouette,
/// and a soft light-to-shade gradient so it reads as cloth, not flat shapes.
class VectorGarmentPainter extends CustomPainter {
  final List<VectorPart> parts;
  final Color base;

  /// Colour per zone id; zones not listed take the garment colour.
  final Map<String, Color> zoneColors;

  const VectorGarmentPainter({
    required this.parts,
    required this.base,
    required this.zoneColors,
  });

  static final Expando<Path> _silhouettes = Expando<Path>();

  Path get _silhouette =>
      _silhouettes[parts] ??= VectorGarments.silhouette(parts);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 1024);
    final outline = Paint()
      ..color = Colors.black.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeJoin = StrokeJoin.round;

    for (final part in parts) {
      final color = part.zone == 'body'
          ? base
          : part.zone == 'detail'
          ? Colors.black.withValues(alpha: part.shade)
          : (zoneColors[part.zone] ?? base);
      if (part.stroke == null) {
        canvas.drawPath(part.path, Paint()..color = color);
        if (part.zone != 'detail') canvas.drawPath(part.path, outline);
        continue;
      }
      final clipped =
          part.zone == 'collar' ||
          part.zone == 'cuffs' ||
          part.zone == 'detail';
      canvas.save();
      if (clipped) canvas.clipPath(_silhouette);
      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (part.zone != 'detail' && !clipped) {
        canvas.drawPath(
          part.path,
          stroke
            ..strokeWidth = part.stroke! + 5
            ..color = Colors.black.withValues(alpha: 0.22),
        );
      }
      canvas.drawPath(
        part.path,
        stroke
          ..strokeWidth = part.stroke!
          ..color = color,
      );
      canvas.restore();
    }

    // Cloth shading over the whole silhouette.
    canvas.save();
    canvas.clipPath(_silhouette);
    final box = const Rect.fromLTWH(0, 0, 1024, 1024);
    canvas.drawRect(
      box,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
            Colors.black.withValues(alpha: 0.14),
          ],
        ).createShader(box),
    );
    canvas.drawRect(
      box,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.08)],
          stops: const [0.55, 1.0],
        ).createShader(box),
    );
    canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(VectorGarmentPainter old) =>
      !identical(old.parts, parts) ||
      old.base != base ||
      !mapEquals(old.zoneColors, zoneColors);
}

/// Dashed print-area box, [area] given in the 1024-unit space of a style photo.
class PrintGuidePainter extends CustomPainter {
  final Rect area;
  const PrintGuidePainter(this.area);

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 1024;
    final r = Rect.fromLTRB(
      area.left * k,
      area.top * k,
      area.right * k,
      area.bottom * k,
    );
    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    const dash = 6.0;
    void edge(Offset a, Offset b) {
      final total = (b - a).distance;
      final dir = (b - a) / total;
      for (double d = 0; d < total; d += dash * 2) {
        canvas.drawLine(
          a + dir * d,
          a + dir * (d + dash).clamp(0, total).toDouble(),
          paint,
        );
      }
    }

    edge(r.topLeft, r.topRight);
    edge(r.topRight, r.bottomRight);
    edge(r.bottomRight, r.bottomLeft);
    edge(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(PrintGuidePainter old) => old.area != area;
}
