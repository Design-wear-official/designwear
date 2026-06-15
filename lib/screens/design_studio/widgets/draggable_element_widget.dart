import 'package:flutter/material.dart';
import 'package:designwear/presentation/styles/styles.dart';

class DraggableElementWidget extends StatefulWidget {
  final String id;
  final bool isSelected;
  final double currentX;
  final double currentY;
  final Widget child;
  final Function(String?) onElementSelected;
  final Function(double, double) onPositionUpdate;

  const DraggableElementWidget({
    super.key,
    required this.id,
    required this.isSelected,
    required this.currentX,
    required this.currentY,
    required this.child,
    required this.onElementSelected,
    required this.onPositionUpdate,
  });

  @override
  State<DraggableElementWidget> createState() => _DraggableElementWidgetState();
}

class _DraggableElementWidgetState extends State<DraggableElementWidget> {
  Offset _dragDelta = Offset.zero;
  bool _isDragging = false;

  @override
  void didUpdateWidget(DraggableElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset delta when position is committed from outside (after drag end)
    if (oldWidget.currentX != widget.currentX ||
        oldWidget.currentY != widget.currentY) {
      _dragDelta = Offset.zero;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => widget.onElementSelected(widget.isSelected ? null : widget.id),
      onPanStart: (_) {
        setState(() {
          _isDragging = true;
          _dragDelta = Offset.zero;
        });
      },
      onPanUpdate: (details) {
        setState(() => _dragDelta += details.delta);
      },
      onPanEnd: (_) {
        final newX = widget.currentX + _dragDelta.dx;
        final newY = widget.currentY + _dragDelta.dy;
        setState(() {
          _isDragging = false;
          _dragDelta = Offset.zero;
        });
        widget.onPositionUpdate(newX, newY);
      },
      onPanCancel: () {
        setState(() {
          _isDragging = false;
          _dragDelta = Offset.zero;
        });
      },
      child: Transform.translate(
        offset: _isDragging ? _dragDelta : Offset.zero,
        child: Container(
          decoration: BoxDecoration(
            border: widget.isSelected
                ? Border.all(color: AppColors.marigold, width: 2)
                : _isDragging
                    ? Border.all(
                        color: AppColors.marigold.withValues(alpha: 0.4),
                        width: 1,
                      )
                    : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
