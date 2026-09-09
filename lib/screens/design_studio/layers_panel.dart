import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'design_studio_utils.dart';

class LayersPanel extends StatelessWidget {
  final CustomDesign design;
  final String? selectedElementId;
  final String? provenanceLabel;
  final Function(String?) onElementSelected;
  final Function(String) onDuplicateElement;
  final Function(String) onDeleteElement;
  final Function(int oldIndex, int newIndex) onReorderElements;
  final VoidCallback? onClose;
  final VoidCallback? onAddLayerTap;

  const LayersPanel({
    super.key,
    required this.design,
    required this.selectedElementId,
    required this.onElementSelected,
    required this.onDuplicateElement,
    required this.onDeleteElement,
    required this.onReorderElements,
    this.provenanceLabel,
    this.onClose,
    this.onAddLayerTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          if (onClose != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LAYERS',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      letterSpacing: 1.1,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
          
          Builder(builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Text(
                'INHERITED FROM ORIGINAL',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: AppColors.dsTextSecondary(isDark),
                  letterSpacing: 0.6,
                ),
              ),
            );
          }),

          // Layers List
          Expanded(child: _buildLayersList(context)),
        ],
      ),
    );
  }

  Widget _buildLayersList(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = AppColors.dsCardBg(isDark);
    final hair = AppColors.dsBorder(isDark);

    final allLayers = DesignStudioUtils.generateLayersData(design);

    // We build:
    // 1. Base fabric color layer (Teal/Indigo...)
    // 2. Custom elements layers
    // 3. Add layer button (dashed)

    final List<Widget> listItems = [];

    // Fabric Color Layer
    listItems.add(
      _buildLayerRow(
        context: context,
        icon: Icons.circle,
        iconColor: DesignStudioUtils.parseColorFromHex(design.baseColor),
        title: 'Tee colour — ${design.productType}',
        sourceText: 'from original',
        isLegacy: true,
      ),
    );

    // Print Placement Layer
    listItems.add(
      _buildLayerRow(
        context: context,
        icon: Icons.center_focus_strong,
        title: 'Print area — ${design.printLocation == 'centre_chest' ? 'Centre chest' : 'Left chest'}',
        sourceText: 'from original',
        isLegacy: true,
      ),
    );

    // Draggable elements layers
    for (int i = 0; i < allLayers.length; i++) {
      final layer = allLayers[i];
      final isSelected = selectedElementId == layer['id'];
      final isLegacyItem = layer['id'] == 'legacy_text' || layer['id'] == 'legacy_sticker';

      listItems.add(
        GestureDetector(
          onTap: () => onElementSelected(isSelected ? null : layer['id'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.marigold.withValues(alpha: 0.08)
                  : paper,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: isSelected
                    ? AppColors.marigold
                    : hair,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              dense: true,
              leading: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: hair),
                ),
                child: Icon(layer['icon'] as IconData, size: 16, color: Theme.of(context).colorScheme.onSurface),
              ),
              title: Text(
                layer['name'] as String,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              subtitle: Text(
                isLegacyItem ? 'from original' : 'your remix',
                style: GoogleFonts.spaceMono(
                  fontSize: 9.5,
                  fontWeight: FontWeight.bold,
                  color: isLegacyItem
                      ? AppColors.dsTextSecondary(isDark)
                      : AppColors.stone,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => onDuplicateElement(layer['id'] as String),
                    icon: const Icon(Icons.copy, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    tooltip: 'Duplicate',
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => onDeleteElement(layer['id'] as String),
                    icon: const Icon(Icons.delete, size: 14),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 16,
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Add your layer row
    listItems.add(
      GestureDetector(
        onTap: onAddLayerTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: AppColors.dsAccent,
              width: 1.5,
              style: BorderStyle.solid, // Flutter doesn't have native dashed border natively easily without custom paint
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.add, size: 18, color: AppColors.marigold),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add your layer',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.marigold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'your remix',
                      style: GoogleFonts.spaceMono(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.stone,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: listItems,
    );
  }

  Widget _buildLayerRow({
    required BuildContext context,
    required IconData icon,
    Color? iconColor,
    required String title,
    required String sourceText,
    required bool isLegacy,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = AppColors.dsCardBg(isDark);
    final hair = AppColors.dsBorder(isDark);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: hair),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: hair),
            ),
            child: Icon(
              icon,
              size: 16,
              color: iconColor ?? Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sourceText,
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dsTextSecondary(isDark),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
