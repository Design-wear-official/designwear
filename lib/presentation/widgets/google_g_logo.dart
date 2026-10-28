import 'dart:math' as math;

import 'package:flutter/material.dart';

/// The four-colour Google "G", drawn as a vector so it needs no image asset.
class GoogleGLogo extends StatelessWidget {
  const GoogleGLogo({super.key, this.size = 22});
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Google',
    child: SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GPainter()),
    ),
  );
}

class _GPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _red = Color(0xFFEA4335);
  static const _yellow = Color(0xFFFBBC05);
  static const _green = Color(0xFF34A853);

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.2;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - stroke / 2,
    );
    double rad(double deg) => deg * math.pi / 180;

    void arc(Color color, double fromDeg, double toDeg) {
      canvas.drawArc(
        rect,
        rad(fromDeg),
        rad(toDeg - fromDeg),
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke,
      );
    }

    // Angles run clockwise from the right-hand side; the gap is the G's mouth.
    arc(_red, 218, 318);
    arc(_yellow, 138, 218);
    arc(_green, 40, 138);
    arc(_blue, 0, 40);

    // The blue bar into the middle of the letter.
    final centre = size.center(Offset.zero);
    canvas.drawRect(
      Rect.fromLTWH(
        centre.dx,
        centre.dy - stroke / 2,
        size.width / 2 - 0.5,
        stroke,
      ),
      Paint()..color = _blue,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
