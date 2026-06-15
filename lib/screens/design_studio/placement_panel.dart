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
          'Print location',
          style: GoogleFonts.spaceMono(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: isDark ? AppColors.stone : const Color(0xFF7A7B82),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: [
            _buildOptionButton(
              context: context,
              title: 'Centre chest',
              subtitle: 'Inherited',
              isSelected: isCentre,
              onTap: () {
                onDesignUpdate(design.copyWith(printLocation: 'centre_chest'));
              },
            ),
            _buildOptionButton(
              context: context,
              title: 'Left chest',
              subtitle: 'Pocket',
              isSelected: isLeft,
              onTap: () {
                onDesignUpdate(design.copyWith(printLocation: 'left_chest'));
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? card : paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? (isDark ? Colors.white : Colors.black)
                : hair,
            width: isSelected ? 2.0 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: isSelected ? (isDark ? Colors.white : Colors.black) : (isDark ? AppColors.stone : Colors.black54),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.outfit(
                fontSize: 11,
                color: isSelected ? AppColors.marigold : (isDark ? AppColors.stone.withOpacity(0.7) : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
