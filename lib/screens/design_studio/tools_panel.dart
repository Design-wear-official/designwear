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
      'id': 'place',
      'label': 'Placement',
      'iconOutline': Icons.aspect_ratio_outlined,
      'iconFilled': Icons.aspect_ratio,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    final child = isVertical
        ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: tools.map((tool) => _buildToolButton(context, tool)).toList(),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tools.map((tool) => Expanded(child: _buildToolButton(context, tool))).toList(),
          );

    return Container(
      decoration: BoxDecoration(
        color: card,
        border: isVertical
            ? Border(right: BorderSide(color: hair, width: 1))
            : Border(top: BorderSide(color: hair, width: 1)),
      ),
      padding: isVertical
          ? const EdgeInsets.symmetric(vertical: 16, horizontal: 8)
          : const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: child,
    );
  }

  Widget _buildToolButton(BuildContext context, Map<String, dynamic> tool) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final id = tool['id'] as String;
    final isSelected = activeTool == id;

    final color = isSelected
        ? (isDark ? Colors.white : const Color(0xFF15182B))
        : (isDark ? AppColors.stone : const Color(0xFF7A7B82));

    final iconColor = isSelected ? AppColors.marigold : color;

    final buttonContent = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSelected ? tool['iconFilled'] as IconData : tool['iconOutline'] as IconData,
          color: iconColor,
          size: isVertical ? 20 : 18,
        ),
        SizedBox(height: isVertical ? 5 : 2),
        Flexible(
          child: Text(
            tool['label'] as String,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: isVertical ? 10 : 9,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
              letterSpacing: isVertical ? 0.2 : 0.1,
            ),
          ),
        ),
      ],
    );

    return GestureDetector(
      onTap: () => onToolSelected(id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: isVertical
            ? const EdgeInsets.symmetric(vertical: 16)
            : const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFF15182B).withValues(alpha: 0.04))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: buttonContent,
      ),
    );
  }
}
