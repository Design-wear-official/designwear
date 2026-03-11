import 'package:flutter/material.dart';
import '../../models/custom_design.dart';
import '../../services/design_template_service.dart';
import 'design_studio_constants.dart';
import 'widgets/colors_tab.dart';
import 'widgets/text_tab.dart';
import 'widgets/stickers_tab.dart';
import 'widgets/templates_tab.dart';

class ToolsPanel extends StatefulWidget {
  final CustomDesign design;
  final String? selectedElementId;
  final DesignTemplateService templateService;
  final Function(CustomDesign) onDesignUpdate;
  final Function(String) onAddTextElement;
  final Function(String) onAddStickerElement;
  final Function(DesignElement, String) onToggleTextEffect;

  const ToolsPanel({
    super.key,
    required this.design,
    required this.selectedElementId,
    required this.templateService,
    required this.onDesignUpdate,
    required this.onAddTextElement,
    required this.onAddStickerElement,
    required this.onToggleTextEffect,
  });

  @override
  State<ToolsPanel> createState() => _ToolsPanelState();
}

class _ToolsPanelState extends State<ToolsPanel> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Tab bar
          Row(children: _buildTabButtons()),
          const SizedBox(height: 16),

          // Tab content
          Expanded(child: _buildTabContent()),
        ],
      ),
    );
  }

  List<Widget> _buildTabButtons() {
    return DesignStudioConstants.toolTabs.asMap().entries.map((entry) {
      final index = entry.key;
      final tab = entry.value;
      final isSelected = _selectedTab == index;

      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _selectedTab = index),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  tab['icon'] as IconData,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  tab['label'] as String,
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return ColorsTab(
          design: widget.design,
          onDesignUpdate: widget.onDesignUpdate,
        );
      case 1:
        return TextTab(
          design: widget.design,
          selectedElementId: widget.selectedElementId,
          templateService: widget.templateService,
          onDesignUpdate: widget.onDesignUpdate,
          onAddTextElement: widget.onAddTextElement,
          onToggleTextEffect: widget.onToggleTextEffect,
        );
      case 2:
        return StickersTab(onAddStickerElement: widget.onAddStickerElement);
      case 3:
        return TemplatesTab(
          templateService: widget.templateService,
          onApplyTemplate: (template) {
            widget.onDesignUpdate(
              template.design.copyWith(
                // Preserve any existing legacy elements
                text: widget.design.text,
                textX: widget.design.textX,
                textY: widget.design.textY,
                fontSize: widget.design.fontSize,
                textColor: widget.design.textColor,
                sticker: widget.design.sticker,
                stickerX: widget.design.stickerX,
                stickerY: widget.design.stickerY,
                stickerSize: widget.design.stickerSize,
              ),
            );
          },
        );
      default:
        return ColorsTab(
          design: widget.design,
          onDesignUpdate: widget.onDesignUpdate,
        );
    }
  }
}
