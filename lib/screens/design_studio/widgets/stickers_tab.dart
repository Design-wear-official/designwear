import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/screens/design_studio/design_studio_constants.dart';

class StickersTab extends StatelessWidget {
  final Function(String) onAddStickerElement;

  const StickersTab({super.key, required this.onAddStickerElement});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STICKERS & EMOJI',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemCount: DesignStudioConstants.availableStickers.length,
            itemBuilder: (context, index) {
              final sticker = DesignStudioConstants.availableStickers[index];
              return GestureDetector(
                onTap: () => onAddStickerElement(sticker),
                child: Container(
                  decoration: BoxDecoration(
                    color: paper,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: hair),
                  ),
                  child: Center(
                    child: Text(sticker, style: const TextStyle(fontSize: 22)),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
