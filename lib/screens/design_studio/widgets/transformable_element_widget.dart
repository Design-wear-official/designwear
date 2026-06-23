import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/screens/design_studio/design_studio_constants.dart';

/// Direct-manipulation wrapper for a design element on the canvas.
///
/// Supports: tap-to-select, drag-to-move (clamped to the print area),
/// corner resize, rotate handle, and a delete handle. Live gestures call
/// [onPreview] (no undo entry); the gesture end calls [onCommit] (push history).
class TransformableElementWidget extends StatefulWidget {
  final DesignElement element;
  final bool isSelected;
  final ValueChanged<String?> onSelected;
  final ValueChanged<DesignElement> onPreview;
  final VoidCallback onCommit;
  final VoidCallback? onDelete;
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

  void _commitMove() {
    final el = widget.element;
    final nx = (el.x + _moveDelta.dx)
        .clamp(DesignStudioConstants.printAreaMinX, DesignStudioConstants.printAreaMaxX);
    final ny = (el.y + _moveDelta.dy)
        .clamp(DesignStudioConstants.printAreaMinY, DesignStudioConstants.printAreaMaxY);
    setState(() {
      _moveDelta = Offset.zero;
      _moving = false;
    });
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
    final deg = angle * 180 / math.pi + 90;
    widget.onPreview(widget.element.copyWith(rotation: deg));
  }

  @override
  Widget build(BuildContext context) {
    final el = widget.element;
    final selected = widget.isSelected;

    Widget content = Opacity(opacity: el.opacity.clamp(0.0, 1.0), child: widget.child);
    content = Transform.rotate(
      angle: el.rotation * math.pi / 180,
      child: content,
    );

    return Transform.translate(
      offset: _moving ? _moveDelta : Offset.zero,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Body — tap to select, drag to move
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => widget.onSelected(selected ? null : el.id),
            onPanStart: (_) => setState(() {
              _moving = true;
              _moveDelta = Offset.zero;
            }),
            onPanUpdate: (d) => setState(() => _moveDelta += d.delta),
            onPanEnd: (_) => _commitMove(),
            onPanCancel: () => setState(() {
              _moving = false;
              _moveDelta = Offset.zero;
            }),
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
