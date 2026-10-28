import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';

/// Garment construction options — collar, pocket, sleeve cuff and fabric finish.
///
/// These live under the **Shapes** tool (which owns garment form), while the
/// **Colours** tool owns colour. Every option flows through [CustomDesign] and
/// renders on the canvas via `GarmentOverlayPainter`.
class GarmentOptions extends StatelessWidget {
  final CustomDesign design;
  final ValueChanged<CustomDesign> onDesignUpdate;

  const GarmentOptions({
    super.key,
    required this.design,
    required this.onDesignUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Collar Style', isDark),
        const SizedBox(height: 10),
        _chips(
          options: const [
            {
              'id': 'crew',
              'label': 'Crew',
              'icon': Icons.radio_button_unchecked,
            },
            {'id': 'vneck', 'label': 'V-Neck', 'icon': Icons.change_history},
            {
              'id': 'polo',
              'label': 'Polo',
              'icon': Icons.vertical_align_bottom,
            },
          ],
          selected: design.collarStyle,
          onSelect: (id) => onDesignUpdate(design.copyWith(collarStyle: id)),
          isDark: isDark,
        ),

        const SizedBox(height: 16),
        _divider(isDark),
        const SizedBox(height: 16),

        _label('Pocket', isDark),
        const SizedBox(height: 10),
        _chips(
          options: const [
            {'id': 'none', 'label': 'None', 'icon': Icons.block},
            {'id': 'left', 'label': 'Left', 'icon': Icons.square_outlined},
            {'id': 'right', 'label': 'Right', 'icon': Icons.square_outlined},
            {'id': 'both', 'label': 'Both', 'icon': Icons.view_column_outlined},
          ],
          selected: design.pocketStyle,
          onSelect: (id) => onDesignUpdate(design.copyWith(pocketStyle: id)),
          isDark: isDark,
        ),

        const SizedBox(height: 16),
        _divider(isDark),
        const SizedBox(height: 16),

        _label('Sleeve Cuffs', isDark),
        const SizedBox(height: 10),
        _chips(
          options: const [
            {'id': 'none', 'label': 'Plain', 'icon': Icons.block},
            {'id': 'banded', 'label': 'Banded', 'icon': Icons.horizontal_rule},
            {'id': 'rolled', 'label': 'Rolled', 'icon': Icons.drag_handle},
          ],
          selected: design.sleeveCuff,
          onSelect: (id) => onDesignUpdate(design.copyWith(sleeveCuff: id)),
          isDark: isDark,
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
