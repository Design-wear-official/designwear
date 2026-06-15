import 'package:flutter/material.dart';
import 'package:designwear/presentation/styles/styles.dart';

/// Garment types supported by [GarmentTile].
enum GarmentShape { tshirt, hoodie, polo, cap, totebag }

/// A widget that renders a garment silhouette (tee by default) on a
/// grid-background tile, matching the demo `.gtile` + `.garment` pattern.
///
/// Usage:
/// ```dart
/// GarmentTile(
///   color: Color(0xFF2C5F5A),
///   shape: GarmentShape.tshirt,
///   showArt: true,
///   artText: 'PETRICHOR',
/// )
/// ```
class GarmentTile extends StatelessWidget {
  final Color garmentColor;
  final GarmentShape shape;
  final bool showArt;
  final bool showPrint;
  final String? artText;
  final double? width;
  final double? height;
  final double? aspectRatio;
  final BorderRadius borderRadius;

  const GarmentTile({
    super.key,
    this.garmentColor = AppColors.garmentDefault,
    this.shape = GarmentShape.tshirt,
    this.showArt = false,
    this.showPrint = false,
    this.artText,
    this.width,
    this.height,
    this.aspectRatio,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    Widget tile = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.2,
          colors: [card, paper],
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Grid background
            CustomPaint(
              painter: _GridPainter(color: hair),
              child: const SizedBox.expand(),
            ),
            // Garment
            LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.maxWidth * 0.64;
                return CustomPaint(
                  painter: _GarmentPainter(
                    color: garmentColor,
                    shape: shape,
                    showArt: showArt,
                    showPrint: showPrint,
                    artText: artText,
                    isDark: isDark,
                  ),
                  size: Size(size, size * 0.95),
                );
              },
            ),
          ],
        ),
      ),
    );

    if (aspectRatio != null) {
      tile = AspectRatio(aspectRatio: aspectRatio!, child: tile);
    }

    return tile;
  }
}

// ── Grid painter ──────────────────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  final Color color;
  const _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.45)
      ..strokeWidth = 1;

    const spacing = 24.0;
    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Radial mask — fade grid toward edges
    final maskPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [Colors.transparent, color.withOpacity(0.2)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.dstIn;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), maskPaint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.color != color;
}

// ── Garment painter ───────────────────────────────────────────────────────────

class _GarmentPainter extends CustomPainter {
  final Color color;
  final GarmentShape shape;
  final bool showArt;
  final bool showPrint;
  final String? artText;
  final bool isDark;

  const _GarmentPainter({
    required this.color,
    required this.shape,
    required this.showArt,
    required this.showPrint,
    required this.artText,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (shape) {
      case GarmentShape.tshirt:
        _paintTee(canvas, size);
      case GarmentShape.hoodie:
        _paintHoodie(canvas, size);
      case GarmentShape.polo:
        _paintPolo(canvas, size);
      case GarmentShape.cap:
        _paintCap(canvas, size);
      case GarmentShape.totebag:
        _paintTote(canvas, size);
    }
  }

  /// Maps the demo SVG coordinate space (400×380) to canvas [size].
  Path _scaledPath(List<Offset> points, Size size) {
    const sw = 400.0;
    const sh = 380.0;
    final sx = size.width / sw;
    final sy = size.height / sh;
    final path = Path();
    for (int i = 0; i < points.length; i++) {
      final p = Offset(points[i].dx * sx, points[i].dy * sy);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    return path;
  }

  void _paintTee(Canvas canvas, Size size) {
    final sx = size.width / 400;
    final sy = size.height / 380;

    // Body path matching demo SVG
    final bodyPath = Path();
    bodyPath.moveTo(150 * sx, 28 * sy);
    bodyPath.lineTo(120 * sx, 40 * sy);
    bodyPath.lineTo(74 * sx, 92 * sy);
    bodyPath.lineTo(40 * sx, 150 * sy);
    bodyPath.lineTo(78 * sx, 188 * sy);
    bodyPath.lineTo(120 * sx, 156 * sy);
    bodyPath.lineTo(120 * sx, 360 * sy);
    bodyPath.lineTo(280 * sx, 360 * sy);
    bodyPath.lineTo(280 * sx, 156 * sy);
    bodyPath.lineTo(322 * sx, 188 * sy);
    bodyPath.lineTo(360 * sx, 150 * sy);
    bodyPath.lineTo(326 * sx, 92 * sy);
    bodyPath.lineTo(280 * sx, 40 * sy);
    bodyPath.lineTo(250 * sx, 28 * sy);
    // Collar curve
    bodyPath.quadraticBezierTo(
      242 * sx, 56 * sy,
      200 * sx, 70 * sy,
    );
    bodyPath.quadraticBezierTo(
      158 * sx, 56 * sy,
      150 * sx, 28 * sy,
    );
    bodyPath.close();

    // Fill
    canvas.drawPath(
      bodyPath,
      Paint()..color = color,
    );

    // Drop shadow
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.black.withOpacity(isDark ? 0.35 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(bodyPath, Paint()..color = color);

    // Seam lines
    final seamPaint = Paint()
      ..color = Colors.black.withOpacity(isDark ? 0.1 : 0.2)
      ..strokeWidth = 1.4 * sx
      ..style = PaintingStyle.stroke;
    // Collar seam curve
    final collarSeam = Path();
    collarSeam.moveTo(150 * sx, 28 * sy);
    collarSeam.quadraticBezierTo(158 * sx, 56 * sy, 200 * sx, 70 * sy);
    collarSeam.quadraticBezierTo(242 * sx, 56 * sy, 250 * sx, 28 * sy);
    canvas.drawPath(collarSeam, seamPaint);
    // Side seams
    canvas.drawLine(Offset(120 * sx, 156 * sy), Offset(120 * sx, 360 * sy), seamPaint);
    canvas.drawLine(Offset(280 * sx, 156 * sy), Offset(280 * sx, 360 * sy), seamPaint);

    // Collar ellipse
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(200 * sx, 40 * sy),
        width: 68 * sx,
        height: 24 * sy,
      ),
      Paint()..color = Colors.black.withOpacity(0.15),
    );

    // Print zone dashed outline
    if (showPrint) {
      final printPaint = Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = 1.6 * sx
        ..style = PaintingStyle.stroke;
      final printRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(150 * sx, 118 * sy, 100 * sx, 140 * sy),
        Radius.circular(6 * sx),
      );
      _drawDashedRRect(canvas, printRect, printPaint, 5 * sx, 6 * sx);
    }

    // Art layer
    if (showArt) {
      _drawArt(canvas, size, sx, sy);
    }
  }

  void _paintHoodie(Canvas canvas, Size size) {
    final sx = size.width / 400;
    final sy = size.height / 380;

    final body = Path();
    body.moveTo(155 * sx, 20 * sy);
    body.lineTo(118 * sx, 35 * sy);
    body.lineTo(70 * sx, 85 * sy);
    body.lineTo(38 * sx, 148 * sy);
    body.lineTo(74 * sx, 186 * sy);
    body.lineTo(114 * sx, 152 * sy);
    body.lineTo(114 * sx, 360 * sy);
    body.lineTo(286 * sx, 360 * sy);
    body.lineTo(286 * sx, 152 * sy);
    body.lineTo(326 * sx, 186 * sy);
    body.lineTo(362 * sx, 148 * sy);
    body.lineTo(330 * sx, 85 * sy);
    body.lineTo(282 * sx, 35 * sy);
    body.lineTo(245 * sx, 20 * sy);
    // Hood curve
    body.quadraticBezierTo(235 * sx, 68 * sy, 200 * sx, 72 * sy);
    body.quadraticBezierTo(165 * sx, 68 * sy, 155 * sx, 20 * sy);
    body.close();

    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black.withOpacity(isDark ? 0.35 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(body, Paint()..color = color);

    // Kangaroo pocket
    final pocket = Path();
    pocket.moveTo(160 * sx, 240 * sy);
    pocket.lineTo(240 * sx, 240 * sy);
    pocket.lineTo(240 * sx, 300 * sy);
    pocket.lineTo(160 * sx, 300 * sy);
    pocket.close();
    canvas.drawPath(
      pocket,
      Paint()..color = Colors.black.withOpacity(0.12),
    );

    if (showArt) _drawArt(canvas, size, sx, sy);
  }

  void _paintPolo(Canvas canvas, Size size) {
    final sx = size.width / 400;
    final sy = size.height / 380;

    final body = _scaledPath([
      Offset(152, 30), Offset(122, 42), Offset(76, 94),
      Offset(42, 152), Offset(80, 190), Offset(122, 158),
      Offset(122, 360), Offset(278, 360), Offset(278, 158),
      Offset(320, 190), Offset(358, 152), Offset(324, 94),
      Offset(278, 42), Offset(248, 30),
      Offset(236, 54), Offset(200, 64), Offset(164, 54),
    ], size);

    canvas.drawPath(body, Paint()..color = color);
    canvas.drawPath(
      body,
      Paint()
        ..color = Colors.black.withOpacity(isDark ? 0.35 : 0.18)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
    canvas.drawPath(body, Paint()..color = color);

    // Polo collar flap
    final collar = Path();
    collar.moveTo(168 * sx, 44 * sy);
    collar.lineTo(200 * sx, 60 * sy);
    collar.lineTo(232 * sx, 44 * sy);
    collar.lineTo(218 * sx, 28 * sy);
    collar.lineTo(182 * sx, 28 * sy);
    collar.close();
    canvas.drawPath(collar, Paint()..color = Colors.black.withOpacity(0.18));

    if (showArt) _drawArt(canvas, size, sx, sy);
  }

  void _paintCap(Canvas canvas, Size size) {
    final sx = size.width / 400;
    final sy = size.height / 380;

    // Brim
    final brim = Path();
    brim.moveTo(60 * sx, 230 * sy);
    brim.quadraticBezierTo(200 * sx, 280 * sy, 340 * sx, 230 * sy);
    brim.lineTo(360 * sx, 260 * sy);
    brim.quadraticBezierTo(200 * sx, 320 * sy, 40 * sx, 260 * sy);
    brim.close();
    canvas.drawPath(brim, Paint()..color = color.withRed((color.red * 0.85).round()));

    // Crown
    final crown = Path();
    crown.moveTo(100 * sx, 230 * sy);
    crown.quadraticBezierTo(200 * sx, 60 * sy, 300 * sx, 230 * sy);
    crown.quadraticBezierTo(200 * sx, 250 * sy, 100 * sx, 230 * sy);
    crown.close();
    canvas.drawPath(crown, Paint()..color = color);

    // Centre seam
    canvas.drawLine(
      Offset(200 * sx, 80 * sy),
      Offset(200 * sx, 230 * sy),
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..strokeWidth = 1.2 * sx,
    );

    // Logo area
    if (showArt) {
      _drawArt(canvas, size, sx, sy);
    }
  }

  void _paintTote(Canvas canvas, Size size) {
    final sx = size.width / 400;
    final sy = size.height / 380;

    // Handles
    final handle = Paint()
      ..color = color.withRed((color.red * 0.75).round())
      ..strokeWidth = 14 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final leftHandle = Path();
    leftHandle.moveTo(135 * sx, 80 * sy);
    leftHandle.quadraticBezierTo(120 * sx, 40 * sy, 145 * sx, 30 * sy);
    leftHandle.quadraticBezierTo(170 * sx, 20 * sy, 175 * sx, 80 * sy);
    canvas.drawPath(leftHandle, handle);
    final rightHandle = Path();
    rightHandle.moveTo(225 * sx, 80 * sy);
    rightHandle.quadraticBezierTo(230 * sx, 40 * sy, 255 * sx, 30 * sy);
    rightHandle.quadraticBezierTo(280 * sx, 20 * sy, 265 * sx, 80 * sy);
    canvas.drawPath(rightHandle, handle);

    // Bag body
    final bag = Path();
    bag.moveTo(100 * sx, 80 * sy);
    bag.lineTo(300 * sx, 80 * sy);
    bag.lineTo(310 * sx, 340 * sy);
    bag.lineTo(90 * sx, 340 * sy);
    bag.close();
    canvas.drawPath(bag, Paint()..color = color);

    if (showArt) _drawArt(canvas, size, sx, sy);
  }

  void _drawArt(Canvas canvas, Size size, double sx, double sy) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: artText ?? 'PETRICHOR',
        style: TextStyle(
          color: Colors.white.withOpacity(0.9),
          fontSize: 20 * sx,
          fontWeight: FontWeight.w900,
          letterSpacing: 2 * sx,
          fontFamily: 'Archivo',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        size.width / 2 - textPainter.width / 2,
        size.height * 0.52,
      ),
    );

    // Sub-label
    final subPainter = TextPainter(
      text: TextSpan(
        text: "MONSOON '26",
        style: TextStyle(
          color: AppColors.marigold,
          fontSize: 9 * sx,
          fontWeight: FontWeight.w700,
          letterSpacing: 3 * sx,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    subPainter.layout();
    subPainter.paint(
      canvas,
      Offset(
        size.width / 2 - subPainter.width / 2,
        size.height * 0.52 + textPainter.height + 4 * sy,
      ),
    );

    // Decorative wave marks
    final wavePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2.2 * sx
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    _drawWave(canvas, Offset(168 * sx, 150 * sy), wavePaint, sx);
    _drawWave(canvas, Offset(168 * sx, 168 * sy), wavePaint, sx);
    _drawWave(canvas, Offset(208 * sx, 150 * sy), wavePaint, sx);
    _drawWave(canvas, Offset(208 * sx, 168 * sy), wavePaint, sx);
  }

  void _drawWave(Canvas canvas, Offset start, Paint paint, double sx) {
    final path = Path();
    path.moveTo(start.dx, start.dy);
    path.quadraticBezierTo(
      start.dx + 8 * sx, start.dy - 6 * sx,
      start.dx + 16 * sx, start.dy,
    );
    canvas.drawPath(path, paint);
  }

  void _drawDashedRRect(
      Canvas canvas, RRect rrect, Paint paint, double dash, double gap) {
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double dist = 0;
      while (dist < metric.length) {
        final end = (dist + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(dist, end), paint);
        dist += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_GarmentPainter old) =>
      old.color != color ||
      old.shape != shape ||
      old.showArt != showArt ||
      old.showPrint != showPrint ||
      old.artText != artText;
}
