import 'package:flutter/material.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/services/services.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/screens/studio/editor/support/design_studio_constants.dart';
import 'package:designwear/screens/studio/editor/support/design_studio_utils.dart';

class TextControlsWidget extends StatelessWidget {
  final CustomDesign design;
  final String selectedElementId;
  final DesignTemplateService templateService;
  final Function(CustomDesign) onDesignUpdate;
  final Function(DesignElement, String) onToggleTextEffect;

  const TextControlsWidget({
    super.key,
    required this.design,
    required this.selectedElementId,
    required this.templateService,
    required this.onDesignUpdate,
    required this.onToggleTextEffect,
  });

  @override
  Widget build(BuildContext context) {
    // Handle new text elements
    final element = design.elements
        .where((e) => e.id == selectedElementId)
        .firstOrNull;

    if (element?.type == DesignElementType.text) {
      return _buildNewTextControls(element!);
    }

    return Container();
  }

  Widget _buildNewTextControls(DesignElement element) {
    return Column(
      children: [
        // Font size slider
        Row(
          children: [
            const Icon(Icons.format_size, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Slider(
                value: element.size,
                min: DesignStudioConstants.minFontSize,
                max: DesignStudioConstants.maxFontSize,
                activeColor: AppColors.marigold,
                onChanged: (value) {
                  final updatedElement = element.copyWith(size: value);
                  onDesignUpdate(
                    design.updateElement(element.id, updatedElement),
                  );
                },
              ),
            ),
            Text('${element.size.round()}'),
          ],
        ),

        // Font family selector
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: templateService.getAvailableFonts().map((font) {
            final isSelected = element.properties['fontFamily'] == font;
            return GestureDetector(
              onTap: () {
                final updatedProps = Map<String, dynamic>.from(
                  element.properties,
                );
                updatedProps['fontFamily'] = font;
                final updatedElement = element.copyWith(
                  properties: updatedProps,
                );
                onDesignUpdate(
                  design.updateElement(element.id, updatedElement),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.marigold : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  font,
                  style: DesignStudioUtils.getSafeGoogleFont(
                    font,
                    textStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        // Text color
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              const Icon(Icons.format_color_text, size: 18),
              const SizedBox(width: 8),
              ...[
                Colors.black,
                Colors.white,
                Colors.red,
                Colors.orange,
                Colors.yellow,
                Colors.green,
                Colors.blue,
                Colors.purple,
                Colors.pink,
                Colors.brown,
              ].map((color) {
                final hex =
                    '0x${color.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}';
                final isSelected = element.color == hex;
                return GestureDetector(
                  onTap: () {
                    final updatedElement = element.copyWith(color: hex);
                    onDesignUpdate(
                      design.updateElement(element.id, updatedElement),
                    );
                  },
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.marigold
                            : Colors.grey.shade400,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Text effects
        const SizedBox(height: 12),
        Row(
          children: [
            _buildEffectButton(
              Icons.format_bold,
              'Bold',
              element.properties['bold'] ?? false,
              () => onToggleTextEffect(element, 'bold'),
            ),
            const SizedBox(width: 8),
            _buildEffectButton(
              Icons.format_italic,
              'Italic',
              element.properties['italic'] ?? false,
              () => onToggleTextEffect(element, 'italic'),
            ),
            const SizedBox(width: 8),
            _buildEffectButton(
              Icons.format_underlined,
              'Underline',
              element.properties['underline'] ?? false,
              () => onToggleTextEffect(element, 'underline'),
            ),
            const SizedBox(width: 8),
            _buildEffectButton(
              Icons.blur_on,
              'Shadow',
              element.properties['shadow'] ?? false,
              () => onToggleTextEffect(element, 'shadow'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEffectButton(
    IconData icon,
    String label,
    bool isActive,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isActive ? AppColors.marigold : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : Colors.grey.shade600,
          size: 18,
        ),
      ),
    );
  }
}
