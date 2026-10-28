import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';

import '../support/design_studio_constants.dart';
import '../support/design_studio_utils.dart';
import 'design_canvas_painters.dart';
import 'garment_registry.dart';
import '../widgets/elements/transformable_element_widget.dart';
import '../widgets/elements/design_element_widget.dart';

class DesignCanvas extends StatelessWidget {
  final CustomDesign design;
  final String? selectedElementId;
  final String garmentType;
  final DesignSide side;
  final String? provenanceLabel;
  final ValueChanged<String?> onElementSelected;
  final ValueChanged<DesignElement> onElementPreview;
  final VoidCallback onElementCommit;
  final ValueChanged<String> onElementDelete;
  final ValueChanged<String>? onElementEdit;
  final ValueChanged<DesignSide> onSideChanged;
  final GlobalKey? canvasKey;

  /// Live centre-snap guide state, toggled by element drags.
  final ValueNotifier<({bool v, bool h})>? snapGuides;

  /// When true, renders only the garment + design (no card, grid, toggle,
  /// readout or handles) — used to capture a clean texture for 3D preview.
  final bool bare;

  const DesignCanvas({
    super.key,
    required this.design,
    required this.selectedElementId,
    required this.onElementSelected,
    required this.onElementPreview,
    required this.onElementCommit,
    required this.onElementDelete,
    required this.onSideChanged,
    this.onElementEdit,
    this.garmentType = 'tshirt',
    this.side = DesignSide.front,
    this.provenanceLabel,
    this.canvasKey,
    this.snapGuides,
    this.bare = false,
  });

  bool get _showBack => side == DesignSide.back;
  bool get _isSleeve => side.isSleeve;
  Garment get _garment => GarmentRegistry.byId(garmentType);
  bool get _hasFaceAsset => _garment.hasAsset(side);
  bool get _isNetworkImage => _garment.isNetworkImage(side);

  @override
  Widget build(BuildContext context) {
    // The canvas frame is a fixed white "print card" in both app themes, so
    // the grid drawn on top of it uses a fixed light-gray line rather than a
    // theme-dependent hairline (which would vanish against the white frame
    // in dark mode).
    const hair = Color(0x14141414); // ~8% black

    return RepaintBoundary(
      key: canvasKey,
      child: GestureDetector(
        // Tap empty canvas to deselect.
        behavior: HitTestBehavior.opaque,
        onTap: () => onElementSelected(null),
        child: Container(
          width: DesignStudioConstants.canvasWidth + 32,
          height: DesignStudioConstants.canvasWidth * 1.25 + 32,
          decoration: bare
              ? null
              : BoxDecoration(
                  color: AppColors.dsCanvasFrame,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x40000000), // rgba(0,0,0,0.25)
                      blurRadius: 60,
                      offset: Offset(0, 20),
                    ),
                  ],
                ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Grid lines sub-background
              if (!bare)
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.15,
                    child: CustomPaint(painter: CanvasGridPainter(color: hair)),
                  ),
                ),

              // Sleeve views are drawn (there are no sleeve photos).
              if (_isSleeve)
                SizedBox(
                  width: DesignStudioConstants.canvasWidth,
                  height: DesignStudioConstants.canvasWidth * 1.25,
                  child: CustomPaint(
                    painter: SleevePainter(
                      color: DesignStudioUtils.parseColorFromHex(
                        design.baseColor,
                      ),
                      mirrored: side == DesignSide.right,
                      showGuide: !bare,
                    ),
                  ),
                )
              // Garment artwork for the active face, or a placeholder
              else if (_hasFaceAsset)
                ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    DesignStudioUtils.parseColorFromHex(design.baseColor),
                    BlendMode.modulate,
                  ),
                  child: _isNetworkImage
                      ? Image.network(
                          _garment.imageUrl(side)!,
                          width: DesignStudioConstants.canvasWidth,
                          fit: BoxFit.contain,
                          // Show the bundled local asset while the network
                          // image loads, so there is no blank flash.
                          frameBuilder: (ctx, child, frame, _) {
                            final localPath = side == DesignSide.back
                                ? _garment.backAsset
                                : _garment.frontAsset;
                            if (frame == null && localPath != null) {
                              return Image.asset(
                                localPath,
                                width: DesignStudioConstants.canvasWidth,
                                fit: BoxFit.contain,
                              );
                            }
                            return child;
                          },
                          errorBuilder: (_, _, _) {
                            final fallback =
                                (side == DesignSide.back
                                    ? _garment.backAsset
                                    : _garment.frontAsset) ??
                                'assets/images/tshirt_white.png';
                            return Image.asset(
                              fallback,
                              width: DesignStudioConstants.canvasWidth,
                              fit: BoxFit.contain,
                            );
                          },
                        )
                      : Image.asset(
                          _garment.imageUrl(side)!,
                          width: DesignStudioConstants.canvasWidth,
                          fit: BoxFit.contain,
                        ),
                )
              else
                _buildPlaceholder(context),

              // Collar & pocket overlays (t-shirt front only)
              if (_hasFaceAsset &&
                  side == DesignSide.front &&
                  _garment.supportsCollarPocketOverlay)
                Positioned.fill(
                  child: CustomPaint(
                    painter: GarmentOverlayPainter(
                      tshirtColor: DesignStudioUtils.parseColorFromHex(
                        design.baseColor,
                      ),
                      collarStyle: design.collarStyle,
                      pocketStyle: design.pocketStyle,
                      trimColor: design.trimColor == 'auto'
                          ? null
                          : DesignStudioUtils.parseColorFromHex(
                              design.trimColor,
                            ),
                      sleeveCuff: design.sleeveCuff,
                      fabricFinish: design.fabricFinish,
                    ),
                  ),
                ),

              // Legacy AI graphic (only when there is no editable image layer)
              if (side == DesignSide.front &&
                  design.designImageBase64 != null &&
                  !design.hasImageElement)
                Positioned(
                  left: 86,
                  top: 78,
                  width: 160,
                  height: 160,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.memory(
                      base64Decode(design.designImageBase64!),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

              // Layered elements for the active face
              ...design
                  .elementsForSide(side)
                  .map(
                    (element) => Positioned(
                      left:
                          DesignStudioConstants.elementCanvasOffsetX +
                          element.x,
                      top:
                          DesignStudioConstants.elementCanvasOffsetY +
                          element.y,
                      child: TransformableElementWidget(
                        key: ValueKey(element.id),
                        element: element,
                        isSelected: selectedElementId == element.id,
                        onSelected: onElementSelected,
                        onPreview: (updated) => onElementPreview(updated),
                        onCommit: onElementCommit,
                        onDelete: () => onElementDelete(element.id),
                        onEdit: onElementEdit == null
                            ? null
                            : () => onElementEdit!(element.id),
                        onSnapChanged: (v, h) =>
                            snapGuides?.value = (v: v, h: h),
                        child: DesignElementWidget(element: element),
                      ),
                    ),
                  ),

              // Centre-snap guide lines (shown only while dragging onto centre)
              if (!bare && snapGuides != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: ValueListenableBuilder<({bool v, bool h})>(
                      valueListenable: snapGuides!,
                      builder: (_, g, _) => CustomPaint(
                        painter: SnapGuidePainter(
                          vertical: g.v,
                          horizontal: g.h,
                          color: AppColors.marigold,
                        ),
                      ),
                    ),
                  ),
                ),

              // "from original" chip (top-left) — driven by remix source.
              // Dark translucent chrome — same in both themes, since it sits
              // on top of the garment mockup, not the page.
              if (!bare && provenanceLabel != null)
                Positioned(
                  left: 14,
                  // Below the four-way view toggle, which spans most of the top edge.
                  top: 52,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dsFrameChrome,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.fork_right,
                          size: 11,
                          color: Color(0xFFE8E6DF),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          provenanceLabel!,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                            color: const Color(0xFFE8E6DF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Front / Back toggle pill (top-right) — dark translucent
              // segmented control, same chrome style in both themes.
              if (!bare)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppColors.dsFrameChrome,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final (label, target) in const [
                          ('Front', DesignSide.front),
                          ('Back', DesignSide.back),
                          ('Left', DesignSide.left),
                          ('Right', DesignSide.right),
                        ])
                          _buildSideToggleButton(
                            context,
                            label: label,
                            isActive: side == target,
                            onTap: () => onSideChanged(target),
                          ),
                      ],
                    ),
                  ),
                ),

              // Print Size Readout (bottom-right) — dark translucent chrome.
              if (!bare)
                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.dsFrameChrome,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _isSleeve ? 'PRINT 8 × 10 cm' : 'PRINT 30 × 40 cm',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: const Color(0xFFC9C6BC),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideToggleButton(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    // This toggle lives on the dark translucent canvas-frame chrome, which is
    // identical in both light and dark app themes (it overlays the garment
    // mockup, not the page) — so its own colors are theme-independent.
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: isActive ? const Color(0xFF14161C) : const Color(0xFFC9C6BC),
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final backNoArt = _showBack;
    return SizedBox(
      width: DesignStudioConstants.canvasWidth,
      height: DesignStudioConstants.canvasWidth * 1.25,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.checkroom_outlined,
            size: 64,
            color: onSurface.withValues(alpha: 0.22),
          ),
          const SizedBox(height: 12),
          Text(
            backNoArt ? '${_garment.label} · Back' : _garment.label,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: onSurface.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            backNoArt ? 'Design the back — artwork coming soon' : 'Coming Soon',
            style: GoogleFonts.outfit(
              fontSize: 13,
              color: onSurface.withValues(alpha: 0.3),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
