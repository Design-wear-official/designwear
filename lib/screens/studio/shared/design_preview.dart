import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../presentation/styles/styles.dart';

/// A design's rendered garment: the studio's own PNG preview when there is one,
/// otherwise a tinted blank tee so cards never look empty.
class DesignPreview extends StatelessWidget {
  const DesignPreview({
    super.key,
    this.base64Png,
    this.baseColor,
    this.fit = BoxFit.contain,
  });

  final String? base64Png;

  /// Garment colour as the studio stores it ("0xFFRRGGBB" or "#RRGGBB").
  final String? baseColor;
  final BoxFit fit;

  static Color? parseColor(String? v) {
    if (v == null || v.isEmpty) return null;
    final hex = v.startsWith('0x') ? v.substring(2) : v.replaceFirst('#', '');
    final n = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return n == null ? null : Color(n);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.cardDark : const Color(0xFFF5F3EE);
    final png = base64Png;
    if (png != null && png.isNotEmpty) {
      try {
        return ColoredBox(
          color: bg,
          child: Image.memory(
            base64Decode(png),
            fit: fit,
            gaplessPlayback: true,
          ),
        );
      } catch (_) {}
    }
    final tint = parseColor(baseColor) ?? Colors.white;
    return ColoredBox(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(tint, BlendMode.modulate),
          child: Image.asset(
            'assets/images/tshirt_white.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
