import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'design_studio_constants.dart';
import 'design_studio_utils.dart';
import 'widgets/draggable_element_widget.dart';
import 'widgets/design_element_widget.dart';

class DesignCanvas extends StatelessWidget {
  final CustomDesign design;
  final String? selectedElementId;
  final String garmentType;
  final Function(String?) onElementSelected;
  final Function(CustomDesign) onDesignUpdate;

  const DesignCanvas({
    super.key,
    required this.design,
    required this.selectedElementId,
    required this.onElementSelected,
    required this.onDesignUpdate,
    this.garmentType = 'tshirt',
  });

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

  bool get _hasAsset => _garmentAssets.containsKey(garmentType);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center,
      children: [
        // Canvas backdrop
        Container(
          width: DesignStudioConstants.canvasWidth + 32,
          height: DesignStudioConstants.canvasWidth * 1.25 + 32,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        ),

        // Garment image or "Coming Soon" placeholder
        if (_hasAsset)
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              DesignStudioUtils.parseColorFromHex(design.baseColor),
              BlendMode.modulate,
            ),
            child: Image.asset(
              _garmentAssets[garmentType]!,
              width: DesignStudioConstants.canvasWidth,
              fit: BoxFit.contain,
            ),
          )
        else
          _buildComingSoonPlaceholder(context),

        // Only render editable elements on supported garment types
        if (_hasAsset) ...[
          // Legacy text overlay
          if (design.text.isNotEmpty)
            Positioned(
              left: DesignStudioConstants.textCanvasOffsetX + design.textX,
              top: DesignStudioConstants.textCanvasOffsetY + design.textY,
              child: DraggableElementWidget(
                id: 'legacy_text',
                isSelected: selectedElementId == 'legacy_text',
                currentX: design.textX,
                currentY: design.textY,
                onElementSelected: onElementSelected,
                onPositionUpdate: (x, y) =>
                    onDesignUpdate(design.copyWith(textX: x, textY: y)),
                child: _buildLegacyTextOverlay(),
              ),
            ),

          // Legacy sticker overlay
          if (design.sticker.isNotEmpty)
            Positioned(
              left: DesignStudioConstants.stickerCanvasOffsetX + design.stickerX,
              top: DesignStudioConstants.stickerCanvasOffsetY + design.stickerY,
              child: DraggableElementWidget(
                id: 'legacy_sticker',
                isSelected: selectedElementId == 'legacy_sticker',
                currentX: design.stickerX,
                currentY: design.stickerY,
                onElementSelected: onElementSelected,
                onPositionUpdate: (x, y) =>
                    onDesignUpdate(design.copyWith(stickerX: x, stickerY: y)),
                child: _buildLegacyStickerOverlay(),
              ),
            ),

          // New design elements
          ...design.elements.map((element) => Positioned(
                left: DesignStudioConstants.elementCanvasOffsetX + element.x,
                top: DesignStudioConstants.elementCanvasOffsetY + element.y,
                child: DraggableElementWidget(
                  id: element.id,
                  isSelected: selectedElementId == element.id,
                  currentX: element.x,
                  currentY: element.y,
                  onElementSelected: onElementSelected,
                  onPositionUpdate: (x, y) {
                    final updated = element.copyWith(x: x, y: y);
                    onDesignUpdate(design.updateElement(element.id, updated));
                  },
                  child: DesignElementWidget(element: element),
                ),
              )),
        ],
      ],
    );
  }

  Widget _buildComingSoonPlaceholder(BuildContext context) {
    final label = _garmentLabels[garmentType] ?? garmentType;
    return SizedBox(
      width: DesignStudioConstants.canvasWidth,
      height: DesignStudioConstants.canvasWidth * 1.25,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.25)),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Coming Soon',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegacyTextOverlay() {
    return Text(
      design.text,
      style: GoogleFonts.outfit(
        fontSize: design.fontSize,
        fontWeight: FontWeight.bold,
        color: DesignStudioUtils.parseColorFromHex(design.textColor),
      ),
    );
  }

  Widget _buildLegacyStickerOverlay() {
    return Text(design.sticker, style: TextStyle(fontSize: design.stickerSize));
  }
}
