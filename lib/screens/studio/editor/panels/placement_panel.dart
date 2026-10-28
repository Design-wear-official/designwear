import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';

class PlacementPanel extends StatelessWidget {
  final CustomDesign design;
  final Function(CustomDesign) onDesignUpdate;

  const PlacementPanel({
    super.key,
    required this.design,
    required this.onDesignUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCentre = design.printLocation == 'centre_chest';
    final isLeft = design.printLocation == 'left_chest';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRINT PLACEMENT',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            fontSize: 12,
            color: AppColors.dsTextSecondary(isDark),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 14),
        _buildOptionRow(
          context: context,
          title: 'Centre chest',
          isSelected: isCentre,
          onTap: () =>
              onDesignUpdate(design.copyWith(printLocation: 'centre_chest')),
        ),
        const SizedBox(height: 8),
        _buildOptionRow(
          context: context,
          title: 'Left chest',
          isSelected: isLeft,
          onTap: () =>
              onDesignUpdate(design.copyWith(printLocation: 'left_chest')),
        ),
      ],
    );
  }

  Widget _buildOptionRow({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = AppColors.dsCardBg(isDark);
    final border = AppColors.dsBorder(isDark);
    final textSecondary = AppColors.dsTextSecondary(isDark);
    final textPrimary = AppColors.dsTextPrimary(isDark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: textPrimary,
              ),
            ),
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.dsAccent : Colors.transparent,
                border: Border.all(
                  color: isSelected ? AppColors.dsAccent : textSecondary,
                  width: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
