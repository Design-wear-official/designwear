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

  /// A realistic mock-up of this side (from a print-layers job). Shown over the live canvas while set.
  final String? mockupUrl;

  /// Opens the "Layers & sheet" view; the button is shown only when this is set.
  final VoidCallback? onOpenLayers;

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
    this.mockupUrl,
    this.onOpenLayers,
  });

  bool get _showBack => side == DesignSide.back;
  bool get _isSleeve => side.isSleeve;
  bool get _isPocket => side.isPocket;

  Color get _baseColor => DesignStudioUtils.parseColorFromHex(design.baseColor);

  /// The style (crew, pocket tee, henley, polo) for T-shirt designs.
  GarmentStyle? get _style =>
      GarmentStyles.resolve(garmentType, design.styleId);
  StyleView? get _styleView => _style?.viewFor(side);

  Color? _zoneColor(String zoneId) {
    final hex = design.zoneHex(zoneId);
    return hex == null ? null : DesignStudioUtils.parseColorFromHex(hex);
  }

  /// Garment photo drawn once per tinted zone: the whole shirt in the garment
  /// colour, then each recoloured zone clipped over it in its own colour.
  Widget _buildStyleLayers(StyleView view) {
    final box = DesignStudioConstants.canvasWidth * 1.25;
    final scale = box / 1024;
    Widget tinted(Color c) => ColorFiltered(
      colorFilter: DesignStudioUtils.shirtTint(c),
      child: Image.asset(
        view.asset,
        width: box,
        height: box,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.high,
        isAntiAlias: true,
        gaplessPlayback: true,
      ),
    );
    const frameW = DesignStudioConstants.canvasWidth + 32;
    const frameH = DesignStudioConstants.canvasWidth * 1.25 + 32;
    // Positioned (not a sized box): the square photo is wider than the frame
    // and must keep its true size, centred, so zone shapes line up.
    final vector = view.vector;
    if (vector != null) {
      return Positioned(
        left: (frameW - box) / 2,
        top: (frameH - box) / 2,
        width: box,
        height: box,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: VectorGarmentPainter(
                parts: vector,
                base: _baseColor,
                zoneColors: {
                  for (final z in _style!.zones)
                    if (_zoneColor(z.id) != null) z.id: _zoneColor(z.id)!,
                },
              ),
            ),
            if (design.fabricFinish != 'solid')
              IgnorePointer(
                child: CustomPaint(
                  painter: FabricFinishPainter(
                    garmentColor: _baseColor,
                    finish: design.fabricFinish,
                  ),
                ),
              ),
          ],
        ),
      );
    }
    return Positioned(
      left: (frameW - box) / 2,
      top: (frameH - box) / 2,
      width: box,
      height: box,
      child: Stack(
        fit: StackFit.expand,
        children: [
          tinted(_baseColor),
          for (final entry in view.zones.entries)
            if (_zoneColor(entry.key) != null)
              ClipPath(
                clipper: _ZoneClipper(entry.value.toPath(scale)),
                child: tinted(_zoneColor(entry.key)!),
              ),
          if (design.fabricFinish != 'solid' && !side.isSleeve)
            IgnorePointer(
              child: CustomPaint(
                painter: FabricFinishPainter(
                  garmentColor: _baseColor,
                  finish: design.fabricFinish,
                ),
              ),
            ),
          // Print-area guide on the sleeve photo (dashed box, editor only).
          if (side.isSleeve && !bare)
            IgnorePointer(
              child: CustomPaint(
                painter: PrintGuidePainter(
                  const Rect.fromLTWH(485, 215, 125, 170),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Garment get _garment => GarmentRegistry.byId(garmentType);

  /// The print area of the side being shown, from the garment's own list when it has one.
  String get _printLabel {
    final p = _garment.placementFor(side);
    if (p != null) {
      String n(double v) =>
          v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);
      return 'PRINT ${n(p.widthInches)} × ${n(p.heightInches)} in';
    }
    if (_isPocket) return 'PRINT 8 × 8 cm';
    return _isSleeve ? 'PRINT 8 × 10 cm' : 'PRINT 30 × 40 cm';
  }

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

              // Pocket close-ups are drawn too (no photo of a bare pocket).
              if (_isPocket)
                SizedBox(
                  width: DesignStudioConstants.canvasWidth,
                  height: DesignStudioConstants.canvasWidth * 1.25,
                  child: CustomPaint(
                    painter: PocketAreaPainter(
                      color: _baseColor,
                      pocketColor: _zoneColor('pockets'),
                      showGuide: !bare,
                    ),
                  ),
                )
              // Front / back: the style photo with each zone tinted separately.
              else if (_styleView != null)
                _buildStyleLayers(_styleView!)
              // Sleeve views are drawn (there are no sleeve photos).
              else if (_isSleeve)
                SizedBox(
                  width: DesignStudioConstants.canvasWidth,
                  height: DesignStudioConstants.canvasWidth * 1.25,
                  child: CustomPaint(
                    painter: SleevePainter(
                      color: _zoneColor('sleeves') ?? _baseColor,
                      mirrored: side == DesignSide.right,
                      showGuide: !bare,
                    ),
                  ),
                )
              // Other garments: one photo tinted with the garment colour.
              else if (_hasFaceAsset)
                ColorFiltered(
                  colorFilter: DesignStudioUtils.shirtTint(
                    DesignStudioUtils.parseColorFromHex(design.baseColor),
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
                                'assets/images/garments/crew_front.png';
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
                          filterQuality: FilterQuality.high,
                        ),
                )
              else
                _buildPlaceholder(context),

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
                      filterQuality: FilterQuality.high,
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
                  // Below the two-row view toggle, which spans most of the top edge.
                  top: 80,
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

              // The realistic mock-up of this side, while the design is what the job made. If it cannot
              // load, the live canvas underneath stays visible.
              if (!bare && mockupUrl != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Image.network(
                      mockupUrl!,
                      key: const ValueKey('mockup-view'),
                      fit: BoxFit.contain,
                      frameBuilder: (ctx, child, frame, _) => frame == null
                          ? const SizedBox.shrink()
                          : ColoredBox(
                              color: AppColors.dsCanvasFrame,
                              child: child,
                            ),
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),

              // Opens the layers and contact sheet of the artwork made by the assistant.
              if (!bare && onOpenLayers != null)
                Positioned(
                  bottom: 14,
                  left: 14,
                  child: GestureDetector(
                    key: const ValueKey('open-layers'),
                    onTap: onOpenLayers,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.dsFrameChrome,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'Layers & sheet',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          color: const Color(0xFFC9C6BC),
                        ),
                      ),
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
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final row in [
                          [
                            ('Front', DesignSide.front),
                            ('Back', DesignSide.back),
                            if (_garment.hasSleeves) ('Left', DesignSide.left),
                            if (_garment.hasSleeves)
                              ('Right', DesignSide.right),
                          ],
                          if (_garment.hasSleeves &&
                              _style?.garment == 'tshirt')
                            [
                              ('L Pocket', DesignSide.leftPocket),
                              ('R Pocket', DesignSide.rightPocket),
                            ],
                        ])
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (final (label, target) in row)
                                _buildSideToggleButton(
                                  context,
                                  label: label,
                                  isActive: side == target,
                                  onTap: () => onSideChanged(target),
                                ),
                            ],
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
                      _printLabel,
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

class _ZoneClipper extends CustomClipper<Path> {
  final Path path;
  _ZoneClipper(this.path);

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_ZoneClipper old) => old.path != path;
}
