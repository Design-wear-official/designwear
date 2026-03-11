import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/custom_design.dart';
import '../../styles/app_colors.dart';
import 'design_studio_constants.dart';
import 'design_studio_utils.dart';

class LayersPanel extends StatelessWidget {
  final CustomDesign design;
  final String? selectedElementId;
  final Function(String?) onElementSelected;
  final Function(String) onDuplicateElement;
  final Function(String) onDeleteElement;
  final VoidCallback onClose;

  const LayersPanel({
    super.key,
    required this.design,
    required this.selectedElementId,
    required this.onElementSelected,
    required this.onDuplicateElement,
    required this.onDeleteElement,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: DesignStudioConstants.layersPanelWidth,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            bottomLeft: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'LAYERS',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                  IconButton(
                    onPressed: onClose,
                    icon: const Icon(Icons.close),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            Expanded(child: _buildLayersList(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildLayersList(BuildContext context) {
    final allLayers = DesignStudioUtils.generateLayersData(design);

    return ReorderableListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      onReorder: (oldIndex, newIndex) {
        // Handle reordering logic here
        if (newIndex > oldIndex) newIndex--;
        // Implementation depends on your layer system
      },
      children: allLayers.map((layer) {
        final isSelected = selectedElementId == layer['id'];

        return Card(
          key: ValueKey(layer['id']),
          margin: const EdgeInsets.only(bottom: 8),
          color: isSelected
              ? AppColors.accentBlue.withValues(alpha: 0.1)
              : null,
          child: ListTile(
            leading: Icon(layer['icon'] as IconData),
            title: Text(
              layer['name'] as String,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              (layer['type'] as String).toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => onDuplicateElement(layer['id'] as String),
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Duplicate',
                ),
                IconButton(
                  onPressed: () => onDeleteElement(layer['id'] as String),
                  icon: const Icon(Icons.delete, size: 16),
                  tooltip: 'Delete',
                ),
              ],
            ),
            onTap: () {
              onElementSelected(isSelected ? null : layer['id'] as String);
            },
          ),
        );
      }).toList(),
    );
  }
}
