import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';

/// Garment construction options — style (crew, pocket tees, henley, polo) and fabric finish.
///
/// These live under the **Shapes** tool (which owns garment form), while the
/// **Colours** tool owns colour. Every option flows through [CustomDesign] and
/// renders on the canvas via `GarmentOverlayPainter`.
class GarmentOptions extends StatelessWidget {
  final CustomDesign design;
  final ValueChanged<CustomDesign> onDesignUpdate;

  /// Garment category being designed ('tshirt', 'hoodie', 'cap', 'totebag').
  final String garmentType;

  const GarmentOptions({
    super.key,
    required this.design,
    required this.onDesignUpdate,
    this.garmentType = 'tshirt',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Style', isDark),
        const SizedBox(height: 10),
        _chips(
          options: [
            for (final st in GarmentStyles.forGarment(garmentType))
              {'id': st.id, 'label': st.label, 'icon': _styleIcon(st.id)},
          ],
          selected:
              GarmentStyles.resolve(garmentType, design.styleId)?.id ??
              design.styleId,
          onSelect: (id) => onDesignUpdate(
            // A style can come with its own part colours (ringer, raglan).
            design.copyWith(
              styleId: id,
              partColors: GarmentStyles.byId(id).defaultParts,
              collarColor: 'auto',
              pocketColor: 'auto',
              cuffColor: 'auto',
            ),
          ),
          isDark: isDark,
        ),
        const SizedBox(height: 6),
        Text(
          (GarmentStyles.resolve(garmentType, design.styleId)?.description ??
              ''),
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? AppColors.stone : const Color(0xFF7A7B82),
          ),
        ),

        const SizedBox(height: 16),
        _divider(isDark),
        const SizedBox(height: 16),

        _label('Fabric Finish', isDark),
        const SizedBox(height: 10),
        _chips(
          options: const [
            {'id': 'solid', 'label': 'Solid', 'icon': Icons.circle},
            {'id': 'heather', 'label': 'Heather', 'icon': Icons.grain},
            {'id': 'vintage', 'label': 'Vintage', 'icon': Icons.blur_on},
          ],
          selected: design.fabricFinish,
          onSelect: (id) => onDesignUpdate(design.copyWith(fabricFinish: id)),
          isDark: isDark,
        ),
      ],
    );
  }

  static IconData _styleIcon(String id) => switch (id) {
    'henley' => Icons.radio_button_checked,
    'vneck' => Icons.change_history,
    'longsleeve' => Icons.swap_horiz,
    'raglan' => Icons.sports_baseball_outlined,
    'ringer' => Icons.album_outlined,
    'tank' => Icons.accessibility_new,
    'hoodie' => Icons.dry_cleaning_outlined,
    'cap' => Icons.sports_baseball,
    'tote' => Icons.shopping_bag_outlined,
    'polo' => Icons.checkroom,
    String s when s.startsWith('crew_pocket') => Icons.square_outlined,
    _ => Icons.radio_button_unchecked,
  };

  Widget _divider(bool isDark) => Container(
    height: 1,
    color: isDark ? const Color(0xFF262B3D) : const Color(0xFFE8E6E0),
  );

  Widget _label(String label, bool isDark) => Text(
    label.toUpperCase(),
    style: GoogleFonts.spaceMono(
      fontWeight: FontWeight.bold,
      fontSize: 11,
      color: isDark ? AppColors.stone : const Color(0xFF7A7B82),
      letterSpacing: 0.8,
    ),
  );

  Widget _chips({
    required List<Map<String, dynamic>> options,
    required String selected,
    required void Function(String) onSelect,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final id = opt['id'] as String;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final isActive = selected == id;
        return GestureDetector(
          onTap: () => onSelect(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? Colors.white : const Color(0xFF15182B))
                  : (isDark
                        ? const Color(0xFF1A1F2E)
                        : const Color(0xFFF2F1ED)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : (isDark
                          ? const Color(0xFF262B3D)
                          : const Color(0xFFDDDBD5)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 13,
                  color: isActive
                      ? (isDark ? const Color(0xFF15182B) : Colors.white)
                      : (isDark ? AppColors.stone : const Color(0xFF7A7B82)),
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive
                        ? (isDark ? const Color(0xFF15182B) : Colors.white)
                        : (isDark ? AppColors.stone : const Color(0xFF7A7B82)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
