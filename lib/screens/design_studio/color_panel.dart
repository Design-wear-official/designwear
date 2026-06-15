import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'design_studio_utils.dart';

class ColorPanel extends StatelessWidget {
  final CustomDesign design;
  final Function(CustomDesign) onDesignUpdate;

  const ColorPanel({
    super.key,
    required this.design,
    required this.onDesignUpdate,
  });

  static const List<Map<String, dynamic>> fabrics = [
    {'name': 'Teal', 'color': Color(0xFF2C5F5A)},
    {'name': 'Indigo', 'color': Color(0xFF27314F)},
    {'name': 'Charcoal', 'color': Color(0xFF2B2E33)},
    {'name': 'Clay', 'color': Color(0xFFB65D3C)},
    {'name': 'Sage', 'color': Color(0xFF7E8B6B)},
    {'name': 'Bone', 'color': Color(0xFFC1BCB1)},
    {'name': 'Gold', 'color': Color(0xFFC9A227)},
  ];

  @override
  Widget build(BuildContext context) {
    // Find active fabric name
    String activeName = fabrics[0]['name'];
    for (final fabric in fabrics) {
      if (DesignStudioUtils.isColorSelected(fabric['color'], design.baseColor)) {
        activeName = fabric['name'];
        break;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Fabric colour — $activeName',
              style: GoogleFonts.spaceMono(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isDark ? AppColors.stone : const Color(0xFF7A7B82),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: fabrics.map((fabric) {
            final color = fabric['color'] as Color;
            final isSelected = DesignStudioUtils.isColorSelected(color, design.baseColor);

            return GestureDetector(
              onTap: () {
                onDesignUpdate(
                  design.copyWith(
                    baseColor: DesignStudioUtils.colorToHex(color),
                  ),
                );
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? const Color(0xFF262B3D) : const Color(0xFFE4E2DA)),
                    width: isSelected ? 3 : 1.5,
                  ),
                  boxShadow: [
                    if (isSelected)
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: isSelected
                    ? Center(
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.black : Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
