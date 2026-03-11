import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/custom_design.dart';

class DesignStudioUtils {
  static TextStyle getTextStyle(
    double fontSize,
    String colorHex,
    String fontFamily,
    bool bold,
    bool italic,
    bool hasShadow,
    String? shadowColor,
    Map<String, dynamic>? shadowOffset,
  ) {
    List<Shadow> shadows = [];
    if (hasShadow) {
      shadows.add(
        Shadow(
          color: shadowColor != null
              ? Color(int.parse(shadowColor.replaceFirst('0x', ''), radix: 16))
              : Colors.black.withValues(alpha: 0.5),
          offset: shadowOffset != null
              ? Offset(shadowOffset['x'] ?? 2.0, shadowOffset['y'] ?? 2.0)
              : const Offset(2.0, 2.0),
          blurRadius: 4.0,
        ),
      );
    }

    return GoogleFonts.getFont(
      fontFamily.toLowerCase(),
      fontSize: fontSize,
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
      color: Color(int.parse(colorHex.replaceFirst('0x', ''), radix: 16)),
      shadows: shadows,
    );
  }

  static String generateElementId(String type) {
    return '${type}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Color parseColorFromHex(String colorHex) {
    return Color(int.parse(colorHex.replaceFirst('0x', ''), radix: 16));
  }

  static String colorToHex(Color color) {
    return '0x${color.value.toRadixString(16).toUpperCase()}';
  }

  static bool isColorSelected(Color color, String designBaseColor) {
    return parseColorFromHex(designBaseColor).value == color.value;
  }

  static List<Map<String, dynamic>> generateLayersData(CustomDesign design) {
    final allLayers = <Map<String, dynamic>>[
      // Legacy elements
      if (design.text.isNotEmpty)
        {
          'id': 'legacy_text',
          'type': 'text',
          'name': design.text,
          'icon': Icons.text_fields,
        },
      if (design.sticker.isNotEmpty)
        {
          'id': 'legacy_sticker',
          'type': 'sticker',
          'name': design.sticker,
          'icon': Icons.emoji_emotions,
        },
      // New elements
      ...design.elements.map(
        (element) => {
          'id': element.id,
          'type': element.type,
          'name': element.content,
          'icon': element.type == 'text'
              ? Icons.text_fields
              : Icons.emoji_emotions,
        },
      ),
    ];
    return allLayers;
  }
}
