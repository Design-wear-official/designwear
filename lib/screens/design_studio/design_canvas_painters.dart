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

/// Draws collar style and pocket overlays on the t-shirt garment.
/// Coordinates calibrated for tshirt_white.png at 300px in a 332×407 canvas.
class GarmentOverlayPainter extends CustomPainter {
  final Color tshirtColor;
  final String collarStyle; // 'crew' | 'vneck' | 'polo'
  final String pocketStyle; // 'none' | 'left' | 'right' | 'both'

  const GarmentOverlayPainter({
    required this.tshirtColor,
    required this.collarStyle,
    required this.pocketStyle,
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

  @override
  void paint(Canvas canvas, Size size) {
    _paintCollar(canvas);
    _paintPockets(canvas);
  }

  void _paintCollar(Canvas canvas) {
    if (collarStyle == 'crew') return;

    final shade = _adjust(tshirtColor, 0.14);
    final fill = Paint()..color = shade..style = PaintingStyle.fill;
    final border = Paint()
      ..color = _adjust(tshirtColor, 0.32)
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
        ..color = _adjust(tshirtColor, 0.38)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(_cx, _collarTopY + 6), Offset(_cx, _collarTopY + 40), line);
      final btn = Paint()
        ..color = _adjust(tshirtColor, 0.42)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(_cx, _collarTopY + 16), 3.5, btn);
      canvas.drawCircle(Offset(_cx, _collarTopY + 30), 3.5, btn);
    }
  }

  void _paintPockets(Canvas canvas) {
    if (pocketStyle == 'none') return;

    final fill = Paint()
      ..color = _adjust(tshirtColor, 0.13)
      ..style = PaintingStyle.fill;
    final stitch = Paint()
      ..color = _adjust(tshirtColor, 0.30)
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
      old.pocketStyle != pocketStyle;
}
