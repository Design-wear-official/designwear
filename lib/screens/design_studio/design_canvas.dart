import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'design_studio_constants.dart';
import 'design_studio_utils.dart';
import 'design_canvas_painters.dart';
import 'garment_registry.dart';
import 'widgets/transformable_element_widget.dart';
import 'widgets/design_element_widget.dart';

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
  Garment get _garment => GarmentRegistry.byId(garmentType);
  bool get _hasFaceAsset => _garment.hasAsset(side);
  bool get _isNetworkImage => _garment.isNetworkImage(side);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

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
                      color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
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

              // Garment artwork for the active face, or a placeholder
              if (_hasFaceAsset)
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
                          errorBuilder: (_, __, ___) {
                            final fallback = (side == DesignSide.back
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
              if (_hasFaceAsset && !_showBack && _garment.supportsCollarPocketOverlay)
                Positioned.fill(
                  child: CustomPaint(
                    painter: GarmentOverlayPainter(
                      tshirtColor:
                          DesignStudioUtils.parseColorFromHex(design.baseColor),
                      collarStyle: design.collarStyle,
                      pocketStyle: design.pocketStyle,
                      trimColor: design.trimColor == 'auto'
                          ? null
                          : DesignStudioUtils.parseColorFromHex(
                              design.trimColor),
                      sleeveCuff: design.sleeveCuff,
                      fabricFinish: design.fabricFinish,
                    ),
                  ),
                ),

              // Legacy AI graphic (only when there is no editable image layer)
              if (!_showBack &&
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
              ...design.elementsForSide(side).map(
                    (element) => Positioned(
                      left: DesignStudioConstants.elementCanvasOffsetX + element.x,
                      top: DesignStudioConstants.elementCanvasOffsetY + element.y,
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
                      builder: (_, g, __) => CustomPaint(
                        painter: SnapGuidePainter(
                          vertical: g.v,
                          horizontal: g.h,
                          color: AppColors.marigold,
                        ),
                      ),
                    ),
                  ),
                ),

              // Provenance chip (top-left) — driven by remix source
              if (!bare && provenanceLabel != null)
                Positioned(
                  left: 14,
                  top: 14,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF261D15)
                          : const Color(0xFFF4E6CD),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF4C3B24)
                            : const Color(0xFFECD6A8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fork_right,
                            size: 11,
                            color: isDark
                                ? const Color(0xFFFFE9C2)
                                : const Color(0xFF6F4710)),
                        const SizedBox(width: 4),
                        Text(
                          provenanceLabel!,
                          style: GoogleFonts.spaceMono(
                            fontWeight: FontWeight.bold,
                            fontSize: 9,
                            color: isDark
                                ? const Color(0xFFFFE9C2)
                                : const Color(0xFF6F4710),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Front / Back toggle pill (top-center)
              if (!bare)
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
                        context,
                        label: 'Front',
                        isActive: !_showBack,
                        onTap: () => onSideChanged(DesignSide.front),
                      ),
                      _buildSideToggleButton(
                        context,
                        label: 'Back',
                        isActive: _showBack,
                        onTap: () => onSideChanged(DesignSide.back),
                      ),
                    ],
                  ),
                ),
              ),

              // Print Size Readout (bottom-right)
              if (!bare)
              Positioned(
                right: 14,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF151824).withValues(alpha: 0.9)
                        : Colors.white.withValues(alpha: 0.9),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? Colors.white : const Color(0xFF15182B))
              : Colors.transparent,
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

  Widget _buildPlaceholder(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final backNoArt = _showBack;
    return SizedBox(
      width: DesignStudioConstants.canvasWidth,
      height: DesignStudioConstants.canvasWidth * 1.25,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.checkroom_outlined,
              size: 64, color: onSurface.withValues(alpha: 0.22)),
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

