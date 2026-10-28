import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/screens/studio/editor/support/design_studio_utils.dart';
import 'package:designwear/screens/studio/editor/support/design_studio_constants.dart';

/// Renders the visual content of a single [DesignElement] (text, sticker,
/// shape, or image). Position, rotation, opacity and selection chrome are
/// handled by the surrounding transformable widget.
class DesignElementWidget extends StatelessWidget {
  final DesignElement element;

  const DesignElementWidget({super.key, required this.element});

  @override
  Widget build(BuildContext context) {
    return switch (element.type) {
      DesignElementType.text => _buildTextElement(),
      DesignElementType.sticker => _buildStickerElement(),
      DesignElementType.shape => _buildShapeElement(),
      DesignElementType.image => _buildImageElement(),
    };
  }

  Widget _buildTextElement() {
    final props = element.properties;
    return Text(
      element.content,
      style: DesignStudioUtils.getTextStyle(
        element.size,
        element.color,
        props['fontFamily'] ?? 'Outfit',
        props['bold'] ?? false,
        props['italic'] ?? false,
        props['shadow'] ?? false,
        props['shadowColor'],
        props['shadowOffset'],
      ),
    );
  }

  Widget _buildStickerElement() {
    return Text(element.content, style: TextStyle(fontSize: element.size));
  }

  Widget _buildShapeElement() {
    final w = element.width ?? DesignStudioConstants.defaultShapeSize;
    final h = element.height ?? DesignStudioConstants.defaultShapeSize;
    return SizedBox(
      width: w,
      height: h,
      child: CustomPaint(
        painter: _ShapePainter(
          shape: element.content.isEmpty ? 'rect' : element.content,
          color: DesignStudioUtils.parseColorFromHex(element.color),
        ),
      ),
    );
  }

  Widget _buildImageElement() {
    final w = element.width ?? DesignStudioConstants.defaultImageSize;
    final h = element.height ?? DesignStudioConstants.defaultImageSize;
    Uint8List? bytes;
    try {
      bytes = base64Decode(element.content);
    } catch (_) {
      bytes = null;
    }
    if (bytes == null) {
      return SizedBox(width: w, height: h);
    }
    return Image.memory(
      bytes,
      width: w,
      height: h,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => SizedBox(width: w, height: h),
    );
  }
}

/// Paints the four supported primitive shapes filled with [color].
class _ShapePainter extends CustomPainter {
  final String shape;
  final Color color;

  const _ShapePainter({required this.shape, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    switch (shape) {
      case 'circle':
        canvas.drawOval(Offset.zero & size, paint);
        break;
      case 'triangle':
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 'line':
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = (size.height * 0.18).clamp(2.0, 24.0)
          ..strokeCap = StrokeCap.round;
        final mid = size.height / 2;
        canvas.drawLine(Offset(0, mid), Offset(size.width, mid), paint);
        break;
      case 'rect':
      default:
        canvas.drawRect(Offset.zero & size, paint);
    }
  }

  @override
  bool shouldRepaint(_ShapePainter old) =>
      old.shape != shape || old.color != color;
}
