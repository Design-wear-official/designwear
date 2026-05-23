import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../models/custom_design.dart';
import '../../../presentation/styles/app_colors.dart';
import '../design_studio_constants.dart';
import '../design_studio_utils.dart';

class ColorsTab extends StatelessWidget {
  final CustomDesign design;
  final Function(CustomDesign) onDesignUpdate;

  const ColorsTab({
    super.key,
    required this.design,
    required this.onDesignUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'T-Shirt Color',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: DesignStudioConstants.tShirtColors.map((color) {
              final isSelected = DesignStudioUtils.isColorSelected(
                color,
                design.baseColor,
              );

              return GestureDetector(
                onTap: () {
                  onDesignUpdate(
                    design.copyWith(
                      baseColor: DesignStudioUtils.colorToHex(color),
                    ),
                  );
                },
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.gold : Colors.grey.shade300,
                      width: isSelected ? 3 : 1,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

