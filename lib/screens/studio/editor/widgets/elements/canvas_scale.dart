import 'package:flutter/widgets.dart';

/// How much the design canvas is magnified on screen (1 = its natural 332 px).
/// Elements read it to turn pointer movement into canvas units, so dragging and
/// resizing stay under the finger when the canvas is drawn larger.
class CanvasScale extends InheritedWidget {
  const CanvasScale({super.key, required this.scale, required super.child});

  final double scale;

  static double of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<CanvasScale>()?.scale ?? 1.0;

  @override
  bool updateShouldNotify(CanvasScale old) => old.scale != scale;
}
