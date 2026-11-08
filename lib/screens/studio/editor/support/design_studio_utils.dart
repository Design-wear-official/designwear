import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';

class DesignStudioUtils {
  /// Colours the (white) shirt photo so the folds and collar stay visible on any colour. A plain
  /// multiply sends black and navy to a flat black; this scales the photo's own brightness by the shirt
  /// colour plus a small lift that grows as the colour gets darker, so shading survives.
  static ColorFilter shirtTint(Color c) {
    final g = shirtGain(c);
    // Each output channel = gain * (the photo's luminance).
    List<double> row(double k) => [k * 0.299, k * 0.587, k * 0.114, 0, 0];
    return ColorFilter.matrix([
      ...row(g.r),
      ...row(g.g),
      ...row(g.b),
      0,
      0,
      0,
      1,
      0,
    ]);
  }

  /// How much of the photo's brightness each channel keeps for shirt colour [c].
  static ({double r, double g, double b}) shirtGain(Color c) {
    final lum = 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b;
    final lift = 0.2 * (1 - lum) * (1 - lum);
    double gain(double ch) => (ch + lift).clamp(0.0, 1.0);
    return (r: gain(c.r), g: gain(c.g), b: gain(c.b));
  }

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
              ? Offset(
                  (shadowOffset['x'] as num?)?.toDouble() ?? 2.0,
                  (shadowOffset['y'] as num?)?.toDouble() ?? 2.0,
                )
              : const Offset(2.0, 2.0),
          blurRadius: 4.0,
        ),
      );
    }

    return getSafeGoogleFont(
      fontFamily,
      textStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontStyle: italic ? FontStyle.italic : FontStyle.normal,
        color: Color(int.parse(colorHex.replaceFirst('0x', ''), radix: 16)),
        shadows: shadows,
      ),
    );
  }

  static TextStyle getSafeGoogleFont(
    String fontFamily, {
    TextStyle? textStyle,
  }) {
    try {
      switch (fontFamily) {
        case 'Outfit':
          return GoogleFonts.outfit(textStyle: textStyle);
        case 'RockSalt':
          return GoogleFonts.rockSalt(textStyle: textStyle);
        case 'Oswald':
          return GoogleFonts.oswald(textStyle: textStyle);
        case 'Pacifico':
          return GoogleFonts.pacifico(textStyle: textStyle);
        case 'BungeeShade':
          return GoogleFonts.bungeeShade(textStyle: textStyle);
        case 'Fredoka':
          return GoogleFonts.fredoka(textStyle: textStyle);
        case 'Comfortaa':
          return GoogleFonts.comfortaa(textStyle: textStyle);
        case 'Righteous':
          return GoogleFonts.righteous(textStyle: textStyle);
        case 'Roboto':
          return GoogleFonts.roboto(textStyle: textStyle);
        case 'Open Sans':
          return GoogleFonts.openSans(textStyle: textStyle);
        case 'Lato':
          return GoogleFonts.lato(textStyle: textStyle);
        case 'Montserrat':
          return GoogleFonts.montserrat(textStyle: textStyle);
        case 'Playfair Display':
          return GoogleFonts.playfairDisplay(textStyle: textStyle);
        case 'Merriweather':
          return GoogleFonts.merriweather(textStyle: textStyle);
        case 'Nunito':
          return GoogleFonts.nunito(textStyle: textStyle);
        case 'Poppins':
          return GoogleFonts.poppins(textStyle: textStyle);
        case 'Raleway':
          return GoogleFonts.raleway(textStyle: textStyle);
        case 'Ubuntu':
          return GoogleFonts.ubuntu(textStyle: textStyle);
        default:
          // Any other Google Fonts family (the assistant may pick one by name, for example "Anton" or
          // "Permanent Marker"); an unknown name throws and falls back to Outfit below.
          return GoogleFonts.getFont(fontFamily, textStyle: textStyle);
      }
    } catch (e) {
      return GoogleFonts.outfit(textStyle: textStyle);
    }
  }

  static String generateElementId(DesignElementType type) {
    return '${type.value}_${DateTime.now().millisecondsSinceEpoch}';
  }

  static Color parseColorFromHex(String colorHex) {
    return Color(int.parse(colorHex.replaceFirst('0x', ''), radix: 16));
  }

  static String colorToHex(Color color) {
    return '0x${color.toARGB32().toRadixString(16).toUpperCase()}';
  }

  static bool isColorSelected(Color color, String designBaseColor) {
    return parseColorFromHex(designBaseColor).toARGB32() == color.toARGB32();
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
          'type': element.type.value,
          'name': element.content,
          'icon': element.type == DesignElementType.text
              ? Icons.text_fields
              : Icons.emoji_emotions,
        },
      ),
    ];
    return allLayers;
  }
}
