import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'design_studio_constants.dart';
import 'design_studio_utils.dart';
import 'widgets/draggable_element_widget.dart';
import 'widgets/design_element_widget.dart';

class DesignCanvas extends StatefulWidget {
  final CustomDesign design;
  final String? selectedElementId;
  final String garmentType;
  final Function(String?) onElementSelected;
  final Function(CustomDesign) onDesignUpdate;
  final GlobalKey? canvasKey;

  const DesignCanvas({
    super.key,
    required this.design,
    required this.selectedElementId,
    required this.onElementSelected,
    required this.onDesignUpdate,
    this.garmentType = 'tshirt',
    this.canvasKey,
  });

  @override
  State<DesignCanvas> createState() => _DesignCanvasState();
}

class _DesignCanvasState extends State<DesignCanvas> {
  bool _showBack = false;

  // Asset map — add entries here as new garment images are added
  static const _garmentAssets = <String, String>{
    'tshirt': 'assets/images/tshirt_white.png',
  };

  static const _garmentLabels = <String, String>{
    'hoodie':  'Hoodie',
    'polo':    'Polo Shirt',
    'cap':     'Cap',
    'totebag': 'Tote Bag',
  };

  bool get _hasAsset => _garmentAssets.containsKey(widget.garmentType);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return RepaintBoundary(
      key: widget.canvasKey,
      child: Container(
        width: DesignStudioConstants.canvasWidth + 32,
      height: DesignStudioConstants.canvasWidth * 1.25 + 32,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -0.6),
          radius: 1.3,
          colors: isDark
              ? [const Color(0xFF1A1D2B), const Color(0xFF0D0F16)]
              : [const Color(0xFFFFFFFF), const Color(0xFFF1F0EC)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hair, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.1),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Grid lines sub-background
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: CustomPaint(
                painter: _CanvasGridPainter(color: hair),
              ),
            ),
          ),

          // Garment image or "Coming Soon" placeholder
          if (_hasAsset)
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                DesignStudioUtils.parseColorFromHex(widget.design.baseColor),
                BlendMode.modulate,
              ),
              child: Image.asset(
                _garmentAssets[widget.garmentType]!,
                width: DesignStudioConstants.canvasWidth,
                fit: BoxFit.contain,
              ),
            )
          else
            _buildComingSoonPlaceholder(context),

          // Only render front design elements if Front view is active
          if (_hasAsset && !_showBack) ...[
            // AI-generated design graphic in the chest print area
            if (widget.design.designImageBase64 != null)
              Positioned(
                left: 86,
                top: 78,
                width: 160,
                height: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.memory(
                    base64Decode(widget.design.designImageBase64!),
                    fit: BoxFit.contain,
                  ),
                ),
              ),



            // New design elements
            ...widget.design.elements.map((element) => Positioned(
                  left: DesignStudioConstants.elementCanvasOffsetX + element.x,
                  top: DesignStudioConstants.elementCanvasOffsetY + element.y,
                  child: DraggableElementWidget(
                    id: element.id,
                    isSelected: widget.selectedElementId == element.id,
                    currentX: element.x,
                    currentY: element.y,
                    onElementSelected: widget.onElementSelected,
                    onPositionUpdate: (x, y) {
                      final updated = element.copyWith(x: x, y: y);
                      widget.onDesignUpdate(widget.design.updateElement(element.id, updated));
                    },
                    child: DesignElementWidget(element: element),
                  ),
                )),
          ] else if (_hasAsset && _showBack) ...[
            // Back visual indicator
            Positioned(
              top: 100,
              child: Opacity(
                opacity: 0.15,
                child: Column(
                  children: [
                    Icon(Icons.checkroom, size: 48, color: isDark ? Colors.white : Colors.black),
                    const SizedBox(height: 4),
                    Text(
                      'BACK VIEW',
                      style: GoogleFonts.spaceMono(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // ── Overlays matching designwear_studio.html ──

          // Provenance chip overlay (top-left)
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF261D15) : const Color(0xFFF4E6CD),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isDark ? const Color(0xFF4C3B24) : const Color(0xFFECD6A8),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fork_right,
                    size: 11,
                    color: isDark ? const Color(0xFFFFE9C2) : const Color(0xFF6F4710),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'from @aanya',
                    style: GoogleFonts.spaceMono(
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                      color: isDark ? const Color(0xFFFFE9C2) : const Color(0xFF6F4710),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Front / Back toggle pill (top-center)
          Positioned(
            top: 14,
            child: Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: hair),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSideToggleButton(
                    label: 'Front',
                    isActive: !_showBack,
                    onTap: () => setState(() => _showBack = false),
                  ),
                  _buildSideToggleButton(
                    label: 'Back',
                    isActive: _showBack,
                    onTap: () => setState(() => _showBack = true),
                  ),
                ],
              ),
            ),
          ),

          // Print Size Readout (bottom-right)
          Positioned(
            right: 14,
            bottom: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF151824).withOpacity(0.9) : Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: hair),
              ),
              child: Text(
                'PRINT 30 × 40 cm',
                style: GoogleFonts.spaceMono(
                  fontWeight: FontWeight.bold,
                  fontSize: 8.5,
                  color: isDark ? AppColors.stone : const Color(0xFF15182B),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    ),);
  }

  Widget _buildSideToggleButton({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? (isDark ? Colors.white : const Color(0xFF15182B)) : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.spaceMono(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: isActive
                ? (isDark ? const Color(0xFF15182B) : Colors.white)
                : (isDark ? AppColors.stone : const Color(0xFF7A7B82)),
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonPlaceholder(BuildContext context) {
    final label = _garmentLabels[widget.garmentType] ?? widget.garmentType;
    return SizedBox(
      width: DesignStudioConstants.canvasWidth,
      height: DesignStudioConstants.canvasWidth * 1.25,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.25)),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coming Soon',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }


}

// Custom painter to draw grid lines on the design canvas
class _CanvasGridPainter extends CustomPainter {
  final Color color;
  const _CanvasGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 1;

    const spacing = 24.0;
    // Vertical lines
    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_CanvasGridPainter old) => old.color != color;
}
