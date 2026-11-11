import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../presentation/styles/styles.dart';

/// Animated size selector chip with scale feedback and web hover cursor.
class SizeChip extends StatefulWidget {
  final String size;
  final bool isSelected;
  final VoidCallback onTap;

  const SizeChip({
    super.key,
    required this.size,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SizeChip> createState() => _SizeChipState();
}

class _SizeChipState extends State<SizeChip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.88,
      upperBound: 1.0,
      value: 1.0,
    );
    _scale = _controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.reverse();
  void _onTapUp(TapUpDetails _) => _controller.forward();
  void _onTapCancel() => _controller.forward();

  @override
  Widget build(BuildContext context) {
    final chip = GestureDetector(
      onTap: widget.onTap,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          // 56×56 ensures ≥48dp touch target on all phones
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.isSelected
                  ? AppColors.marigold
                  : Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: 0.2),
              width: widget.isSelected ? 2.0 : 1.5,
            ),
            color: widget.isSelected ? AppColors.marigold : Colors.transparent,
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: AppColors.marigold.withValues(alpha: 0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            widget.size,
            style: GoogleFonts.outfit(
              color: widget.isSelected
                  ? AppColors.marigoldInk
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );

    if (kIsWeb) {
      return MouseRegion(cursor: SystemMouseCursors.click, child: chip);
    }
    return chip;
  }
}
