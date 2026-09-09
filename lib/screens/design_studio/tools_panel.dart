import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';

class ToolsPanel extends StatelessWidget {
  final String activeTool;
  final Function(String) onToolSelected;
  final bool isVertical;

  const ToolsPanel({
    super.key,
    required this.activeTool,
    required this.onToolSelected,
    this.isVertical = false,
  });

  static const List<Map<String, dynamic>> tools = [
    {
      'id': 'layers',
      'label': 'Layers',
      'iconOutline': Icons.layers_outlined,
      'iconFilled': Icons.layers,
    },
    {
      'id': 'color',
      'label': 'Colour',
      'iconOutline': Icons.palette_outlined,
      'iconFilled': Icons.palette,
    },
    {
      'id': 'text',
      'label': 'Text',
      'iconOutline': Icons.title_outlined,
      'iconFilled': Icons.title,
    },
    {
      'id': 'emoji',
      'label': 'Emoji',
      'iconOutline': Icons.emoji_emotions_outlined,
      'iconFilled': Icons.emoji_emotions,
    },
    {
      'id': 'shapes',
      'label': 'Shapes',
      'iconOutline': Icons.category_outlined,
      'iconFilled': Icons.category,
    },
    {
      'id': 'place',
      'label': 'Placement',
      'iconOutline': Icons.aspect_ratio_outlined,
      'iconFilled': Icons.aspect_ratio,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sidebarBg = AppColors.dsBarBg(isDark);
    final hair = AppColors.dsBorder(isDark);

    final child = isVertical
        ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: tools.map((tool) => _buildToolButton(context, tool)).toList(),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tools.map((tool) => Expanded(child: _buildToolButton(context, tool))).toList(),
          );

    return Container(
      decoration: BoxDecoration(
        color: sidebarBg,
        border: isVertical
            ? Border(right: BorderSide(color: hair, width: 1))
            : Border(top: BorderSide(color: hair, width: 1)),
      ),
      padding: isVertical
          ? const EdgeInsets.symmetric(vertical: 12, horizontal: 10)
          : const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: child,
    );
  }

  Widget _buildToolButton(BuildContext context, Map<String, dynamic> tool) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = tool['id'] as String;
    final isSelected = activeTool == id;

    final inactiveColor = AppColors.dsTextSecondary(isDark);
    final color = isSelected ? AppColors.dsAccentInk : inactiveColor;

    final buttonContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSelected ? tool['iconFilled'] as IconData : tool['iconOutline'] as IconData,
          color: color,
          size: isVertical ? 20 : 18,
        ),
        SizedBox(height: isVertical ? 6 : 2),
        Flexible(
          child: Text(
            tool['label'] as String,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: isVertical ? 11 : 9,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: isVertical ? 0.2 : 0.1,
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => onToolSelected(id),
      child: Container(
        width: isVertical ? 68 : null,
        margin: isVertical ? const EdgeInsets.only(bottom: 6) : EdgeInsets.zero,
        padding: isVertical
            ? const EdgeInsets.symmetric(vertical: 10, horizontal: 4)
            : const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.dsAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: buttonContent,
      ),
    );
  }
}
