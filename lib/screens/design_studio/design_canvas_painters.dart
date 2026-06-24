import 'dart:math' as math;
import 'package:flutter/material.dart';

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

/// Draws collar, pocket, sleeve-cuff and fabric-finish overlays on the t-shirt.
/// Coordinates calibrated for tshirt_white.png at 300px in a 332×407 canvas.
class GarmentOverlayPainter extends CustomPainter {
  final Color tshirtColor;
  final String collarStyle; // 'crew' | 'vneck' | 'polo'
  final String pocketStyle; // 'none' | 'left' | 'right' | 'both'

  /// Explicit accent colour for collar/pocket/cuff trim. When null the trim
  /// auto-derives a contrasting shade from [tshirtColor] (legacy behaviour).
  final Color? trimColor;
  final String sleeveCuff; // 'none' | 'banded' | 'rolled'
  final String fabricFinish; // 'solid' | 'heather' | 'vintage'

  const GarmentOverlayPainter({
    required this.tshirtColor,
    required this.collarStyle,
    required this.pocketStyle,
    this.trimColor,
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

  bool get _hasTrim => trimColor != null;

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

    final fillColor = _hasTrim ? trimColor! : _adjust(tshirtColor, 0.14);
    final borderColor =
        _hasTrim ? _adjust(trimColor!, 0.32) : _adjust(tshirtColor, 0.32);
    final fill = Paint()..color = fillColor..style = PaintingStyle.fill;
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
        Rect.fromLTWH(_cx - _collarHalfW - 6, _collarTopY,
            (_collarHalfW + 6) * 2, 42),
        const Radius.circular(5),
      );
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect, border);
      final line = Paint()
        ..color = borderColor
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(_cx, _collarTopY + 6), Offset(_cx, _collarTopY + 40), line);
      final btn = Paint()
        ..color = _adjust(_hasTrim ? trimColor! : tshirtColor, 0.42)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(_cx, _collarTopY + 16), 3.5, btn);
      canvas.drawCircle(Offset(_cx, _collarTopY + 30), 3.5, btn);
    }
  }

  // ── Pockets ─────────────────────────────────────────────────────────────────

  void _paintPockets(Canvas canvas) {
    if (pocketStyle == 'none') return;

    final fill = Paint()
      ..color = _hasTrim ? trimColor! : _adjust(tshirtColor, 0.13)
      ..style = PaintingStyle.fill;
    final stitch = Paint()
      ..color = _hasTrim ? _adjust(trimColor!, 0.30) : _adjust(tshirtColor, 0.30)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeJoin = StrokeJoin.round;

    void drawPocket(double cx) {
      final rect =
          Rect.fromLTWH(cx - _pocketW / 2, _pocketTopY, _pocketW, _pocketH);
      canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(4)), fill);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              rect.deflate(5), const Radius.circular(2)),
          stitch);
    }

    if (pocketStyle == 'left' || pocketStyle == 'both') {
      drawPocket(_leftPocketCX);
    }
    if (pocketStyle == 'right' || pocketStyle == 'both') {
      drawPocket(_rightPocketCX);
    }
  }

  // ── Sleeve cuffs ─────────────────────────────────────────────────────────────

  void _paintCuffs(Canvas canvas) {
    if (sleeveCuff == 'none') return;

    final bandColor = _hasTrim ? trimColor! : _adjust(tshirtColor, 0.16);
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
      final light = Paint()
        ..color = Colors.white.withValues(alpha: 0.05);
      final dark = Paint()
        ..color = Colors.black.withValues(alpha: 0.05);
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
        ..shader = RadialGradient(
          colors: [
            (lighten ? Colors.white : Colors.white).withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(
            Rect.fromCircle(center: center, radius: torso.width * 0.7));
      canvas.drawRect(torso, wash);

      final vignette = Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: 0.08),
          ],
          stops: const [0.6, 1.0],
        ).createShader(
            Rect.fromCircle(center: center, radius: torso.width * 0.8));
      canvas.drawRect(torso, vignette);
    }

    canvas.restore();
  }

  Color _adjust(Color color, double amount) {
    if (color.computeLuminance() < 0.25) {
      return Color.fromARGB(
        color.alpha,
        (color.red + (255 - color.red) * amount).round().clamp(0, 255),
        (color.green + (255 - color.green) * amount).round().clamp(0, 255),
        (color.blue + (255 - color.blue) * amount).round().clamp(0, 255),
      );
    }
    return Color.fromARGB(
      color.alpha,
      (color.red * (1 - amount)).round().clamp(0, 255),
      (color.green * (1 - amount)).round().clamp(0, 255),
      (color.blue * (1 - amount)).round().clamp(0, 255),
    );
  }

  @override
  bool shouldRepaint(GarmentOverlayPainter old) =>
      old.tshirtColor != tshirtColor ||
      old.collarStyle != collarStyle ||
      old.pocketStyle != pocketStyle ||
      old.trimColor != trimColor ||
      old.sleeveCuff != sleeveCuff ||
      old.fabricFinish != fabricFinish;
}
