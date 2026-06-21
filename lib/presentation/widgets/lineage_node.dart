import 'package:flutter/material.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'garment_tile.dart';

/// A single node in the remix lineage chain.
/// Renders a small garment thumbnail + creator handle + version label,
/// optionally marked as "current" (marigold ring).
class LineageNode extends StatelessWidget {
  final Color garmentColor;
  final String handle;
  final String version;
  final bool isCurrent;
  final String? artText;
  final VoidCallback? onTap;

  const LineageNode({
    super.key,
    required this.garmentColor,
    required this.handle,
    required this.version,
    this.isCurrent = false,
    this.artText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;
    final stone = AppColors.stone;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 112,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Thumb
            Container(
              width: 96,
              height: 112,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent ? AppColors.marigold : hair,
                  width: isCurrent ? 1.6 : 1.4,
                ),
                boxShadow: isCurrent
                    ? [BoxShadow(color: AppColors.marigold.withValues(alpha: 0.32), blurRadius: 8, spreadRadius: 2)]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: GarmentTile(
                  garmentColor: garmentColor,
                  showArt: artText != null && artText!.isNotEmpty,
                  artText: artText,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Handle
            Text(
              handle,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                color: ink,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 3),
            // Version
            Text(
              version,
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9.5,
                color: isCurrent ? AppColors.marigoldInk : stone,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A horizontal dashed stitch connector between [LineageNode]s.
class LineageStitch extends StatelessWidget {
  const LineageStitch({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return SizedBox(
      width: 24,
      child: Padding(
        padding: const EdgeInsets.only(top: 56),
        child: CustomPaint(painter: _DashLinePainter(color: hair)),
      ),
    );
  }
}

class _DashLinePainter extends CustomPainter {
  final Color color;
  const _DashLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dash = 4.0;
    const gap = 3.0;
    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset((x + dash).clamp(0, size.width), 0), paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashLinePainter old) => old.color != color;
}
