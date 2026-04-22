import 'package:flutter/material.dart';
import '../../../styles/app_colors.dart';

class DraggableElementWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onElementSelected(isSelected ? null : id);
      },
      child: Draggable(
        feedback: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.accentBlue.withValues(alpha: 0.5),
              ),
            ),
            child: child,
          ),
        ),
        childWhenDragging: Container(),
        onDragEnd: (details) {
          final RenderBox renderBox = context.findRenderObject() as RenderBox;
          final localPosition = renderBox.globalToLocal(details.offset);

          onPositionUpdate(localPosition.dx - 150, localPosition.dy - 220);
        },
        child: Container(
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: AppColors.accentBlue, width: 2)
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
