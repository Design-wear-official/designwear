import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/screens/design_studio/design_studio_constants.dart';

/// Direct-manipulation wrapper for a design element on the canvas.
///
/// Supports: tap-to-select, double-tap-to-edit, drag-to-move (clamped to the
/// print area, with centre snapping), corner resize, rotate handle (snaps to
/// 45° steps), and a delete handle. Live gestures call [onPreview] (no undo
/// entry); the gesture end calls [onCommit] (push history).
class TransformableElementWidget extends StatefulWidget {
  final DesignElement element;
  final bool isSelected;
  final ValueChanged<String?> onSelected;
  final ValueChanged<DesignElement> onPreview;
  final VoidCallback onCommit;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  /// Reports active centre-snap guides (vertical, horizontal) during a drag.
  final void Function(bool vertical, bool horizontal)? onSnapChanged;
  final Widget child;

  const TransformableElementWidget({
    super.key,
    required this.element,
    required this.isSelected,
    required this.onSelected,
    required this.onPreview,
    required this.onCommit,
    required this.child,
    this.onDelete,
    this.onEdit,
    this.onSnapChanged,
  });

  @override
  State<TransformableElementWidget> createState() =>
      _TransformableElementWidgetState();
}

class _TransformableElementWidgetState
    extends State<TransformableElementWidget> {
  final GlobalKey _bodyKey = GlobalKey();

  // Live move delta (applied as a translate until committed on drag end).
  Offset _moveDelta = Offset.zero;
  bool _moving = false;

  double get _min => DesignStudioConstants.minElementSize;
  double get _max => DesignStudioConstants.maxElementSize;

  // Canvas centre lines in canvas-pixel space, and the element anchor.
  static const double _canvasCenterX =
      (DesignStudioConstants.canvasWidth + 32) / 2; // 166
  static const double _canvasCenterY =
      (DesignStudioConstants.canvasWidth * 1.25 + 32) / 2; // 203.5
  static const double _anchorX = DesignStudioConstants.elementCanvasOffsetX;
  static const double _anchorY = DesignStudioConstants.elementCanvasOffsetY;

  Size? get _bodySize =>
      (_bodyKey.currentContext?.findRenderObject() as RenderBox?)?.size;

  /// Applies centre snapping to a candidate position and reports active guides.
  Offset _applySnap(Offset candidate) {
    final size = _bodySize;
    if (size == null) {
      widget.onSnapChanged?.call(false, false);
      return candidate;
    }
    final el = widget.element;
    double dx = candidate.dx;
    double dy = candidate.dy;
    bool snapV = false, snapH = false;

    final centerX = _anchorX + el.x + dx + size.width / 2;
    if ((centerX - _canvasCenterX).abs() < DesignStudioConstants.snapThreshold) {
      dx = _canvasCenterX - _anchorX - el.x - size.width / 2;
      snapV = true;
    }
    final centerY = _anchorY + el.y + dy + size.height / 2;
    if ((centerY - _canvasCenterY).abs() < DesignStudioConstants.snapThreshold) {
      dy = _canvasCenterY - _anchorY - el.y - size.height / 2;
      snapH = true;
    }
    widget.onSnapChanged?.call(snapV, snapH);
    return Offset(dx, dy);
  }

  void _commitMove() {
    final el = widget.element;
    final nx = (el.x + _moveDelta.dx).clamp(
        DesignStudioConstants.printAreaMinX, DesignStudioConstants.printAreaMaxX);
    final ny = (el.y + _moveDelta.dy).clamp(
        DesignStudioConstants.printAreaMinY, DesignStudioConstants.printAreaMaxY);
    setState(() {
      _moveDelta = Offset.zero;
      _moving = false;
    });
    widget.onSnapChanged?.call(false, false);
    widget.onPreview(el.copyWith(x: nx.toDouble(), y: ny.toDouble()));
    widget.onCommit();
  }

  void _resizeBy(Offset delta) {
    final el = widget.element;
    final change = (delta.dx + delta.dy) / 2;
    if (el.type == DesignElementType.text ||
        el.type == DesignElementType.sticker) {
      final ns = (el.size + change).clamp(_min, _max);
      widget.onPreview(el.copyWith(size: ns.toDouble()));
    } else {
      final w = el.width ?? DesignStudioConstants.defaultShapeSize;
      final h = el.height ?? DesignStudioConstants.defaultShapeSize;
      final factor = ((w + change) / w).clamp(0.2, 5.0);
      final nw = (w * factor).clamp(_min, _max);
      final nh = (h * factor).clamp(_min, _max);
      widget.onPreview(el.copyWith(width: nw.toDouble(), height: nh.toDouble()));
    }
  }

  void _rotateTo(Offset globalPointer) {
    final box = _bodyKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final center = box.localToGlobal(box.size.center(Offset.zero));
    final angle = math.atan2(
      globalPointer.dy - center.dy,
      globalPointer.dx - center.dx,
    );
    // Rotate handle sits above the element, so a pointer directly above
    // (angle -90°) corresponds to 0° rotation.
    var deg = angle * 180 / math.pi + 90;
    // Snap to the nearest 45° step when close.
    final nearest = (deg / 45).round() * 45.0;
    if ((deg - nearest).abs() < 6) deg = nearest;
    widget.onPreview(widget.element.copyWith(rotation: deg));
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.element;
    final selected = widget.isSelected;
    final flipH = el.properties['flipH'] == true;
    final flipV = el.properties['flipV'] == true;

    Widget content = Opacity(opacity: el.opacity.clamp(0.0, 1.0), child: widget.child);
    if (flipH || flipV) {
      content = Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..scale(flipH ? -1.0 : 1.0, flipV ? -1.0 : 1.0),
        child: content,
      );
    }
    content = Transform.rotate(
      angle: el.rotation * math.pi / 180,
      child: content,
    );

    return Transform.translate(
      offset: _moving ? _moveDelta : Offset.zero,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Body — tap to select, double-tap to edit, drag to move
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSelected(selected ? null : el.id),
            onDoubleTap: widget.onEdit,
            onPanStart: (_) => setState(() {
              _moving = true;
              _moveDelta = Offset.zero;
            }),
            onPanUpdate: (d) =>
                setState(() => _moveDelta = _applySnap(_moveDelta + d.delta)),
            onPanEnd: (_) => _commitMove(),
            onPanCancel: () {
              widget.onSnapChanged?.call(false, false);
              setState(() {
                _moving = false;
                _moveDelta = Offset.zero;
              });
            },
            child: Container(
              key: _bodyKey,
              decoration: BoxDecoration(
                border: selected
                    ? Border.all(color: AppColors.marigold, width: 1.5)
                    : _moving
                        ? Border.all(
                            color: AppColors.marigold.withValues(alpha: 0.4),
                            width: 1,
                          )
                        : null,
              ),
              child: content,
            ),
          ),

          if (selected) ...[
            // Delete (top-left)
            if (widget.onDelete != null)
              Positioned(
                left: -12,
                top: -12,
                child: _Handle(
                  icon: Icons.close,
                  color: AppColors.like,
                  onTap: widget.onDelete,
                ),
              ),
            // Rotate (top-center)
            Positioned(
              top: -34,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onPanUpdate: (d) => _rotateTo(d.globalPosition),
                  onPanEnd: (_) => widget.onCommit(),
                  child: const _Handle(icon: Icons.rotate_right),
                ),
              ),
            ),
            // Resize (bottom-right)
            Positioned(
              right: -12,
              bottom: -12,
              child: GestureDetector(
                onPanUpdate: (d) => _resizeBy(d.delta),
                onPanEnd: (_) => widget.onCommit(),
                child: const _Handle(icon: Icons.open_in_full),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;

  const _Handle({required this.icon, this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.marigold;
    final handle = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: c, width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 4),
        ],
      ),
      child: Icon(icon, size: 13, color: c),
    );
    return onTap == null ? handle : GestureDetector(onTap: onTap, child: handle);
  }
}
