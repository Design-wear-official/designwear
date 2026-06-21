import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/models/models.dart';
import 'package:designwear/presentation/styles/styles.dart';
import 'design_studio_utils.dart';

class ColorPanel extends StatefulWidget {
  final CustomDesign design;
  final Function(CustomDesign) onDesignUpdate;

  const ColorPanel({
    super.key,
    required this.design,
    required this.onDesignUpdate,
  });

  @override
  State<ColorPanel> createState() => _ColorPanelState();
}

class _ColorPanelState extends State<ColorPanel> {
  Color? _customColor;

  static const List<Map<String, dynamic>> fabrics = [
    // Whites & Neutrals
    {'name': 'White', 'color': Color(0xFFFFFFFF)},
    {'name': 'Ivory', 'color': Color(0xFFFFFFF0)},
    {'name': 'Bone', 'color': Color(0xFFC1BCB1)},
    {'name': 'Stone', 'color': Color(0xFF9E9E9E)},
    {'name': 'Charcoal', 'color': Color(0xFF2B2E33)},
    {'name': 'Black', 'color': Color(0xFF111111)},
    // Reds & Pinks
    {'name': 'Blush', 'color': Color(0xFFFFB6C1)},
    {'name': 'Rose', 'color': Color(0xFFE8557A)},
    {'name': 'Crimson', 'color': Color(0xFFDC143C)},
    {'name': 'Scarlet', 'color': Color(0xFFFF2400)},
    {'name': 'Burgundy', 'color': Color(0xFF800020)},
    {'name': 'Maroon', 'color': Color(0xFF5C0A17)},
    // Oranges & Yellows
    {'name': 'Peach', 'color': Color(0xFFFFCBA4)},
    {'name': 'Coral', 'color': Color(0xFFFF6B35)},
    {'name': 'Amber', 'color': Color(0xFFF59E0B)},
    {'name': 'Gold', 'color': Color(0xFFC9A227)},
    {'name': 'Honey', 'color': Color(0xFFE8A838)},
    {'name': 'Sand', 'color': Color(0xFFF4D99C)},
    // Greens
    {'name': 'Mint', 'color': Color(0xFF8FC9A2)},
    {'name': 'Sage', 'color': Color(0xFF7E8B6B)},
    {'name': 'Olive', 'color': Color(0xFF6B7C3E)},
    {'name': 'Forest', 'color': Color(0xFF2D5A27)},
    {'name': 'Teal', 'color': Color(0xFF2C5F5A)},
    {'name': 'Emerald', 'color': Color(0xFF006B4B)},
    // Blues
    {'name': 'Sky', 'color': Color(0xFF87BFDC)},
    {'name': 'Denim', 'color': Color(0xFF5878A0)},
    {'name': 'Cobalt', 'color': Color(0xFF2B4590)},
    {'name': 'Indigo', 'color': Color(0xFF27314F)},
    {'name': 'Navy', 'color': Color(0xFF1A1F3C)},
    {'name': 'Slate', 'color': Color(0xFF475569)},
    // Purples
    {'name': 'Lavender', 'color': Color(0xFFC8B8E0)},
    {'name': 'Lilac', 'color': Color(0xFFA78DC4)},
    {'name': 'Plum', 'color': Color(0xFF7B3F8C)},
    {'name': 'Violet', 'color': Color(0xFF5C2D8F)},
    {'name': 'Mauve', 'color': Color(0xFF8B637A)},
    // Browns & Earth
    {'name': 'Clay', 'color': Color(0xFFB65D3C)},
    {'name': 'Rust', 'color': Color(0xFF9B3A1E)},
    {'name': 'Camel', 'color': Color(0xFFC19A6B)},
    {'name': 'Mocha', 'color': Color(0xFF6B4226)},
    {'name': 'Espresso', 'color': Color(0xFF3C1F0F)},
  ];

  String _activeName() {
    if (_customColor != null &&
        DesignStudioUtils.isColorSelected(_customColor!, widget.design.baseColor)) {
      return 'Custom';
    }
    for (final fabric in fabrics) {
      if (DesignStudioUtils.isColorSelected(
          fabric['color'] as Color, widget.design.baseColor)) {
        return fabric['name'] as String;
      }
    }
    return fabrics[0]['name'] as String;
  }

  void _openCustomPicker() {
    final controller = TextEditingController();
    Color previewColor = _customColor ?? const Color(0xFF5a6cff);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            backgroundColor: isDark ? AppColors.cardDark : AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Custom Colour',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? AppColors.textPrimary : AppColors.black,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Preview circle
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: previewColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black26,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: previewColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F#]')),
                    LengthLimitingTextInputFormatter(7),
                  ],
                  style: GoogleFonts.spaceMono(
                    fontSize: 14,
                    color: isDark ? AppColors.textPrimary : AppColors.black,
                  ),
                  decoration: InputDecoration(
                    hintText: '#RRGGBB',
                    hintStyle: GoogleFonts.spaceMono(
                      fontSize: 14,
                      color: AppColors.stone,
                    ),
                    prefixText: '#',
                    prefixStyle: GoogleFonts.spaceMono(
                      fontSize: 14,
                      color: isDark ? AppColors.textPrimary : AppColors.black,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF1A1F2E)
                        : const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onChanged: (val) {
                    final hex = val.startsWith('#') ? val : '#$val';
                    if (hex.length == 7) {
                      try {
                        final color = Color(
                            int.parse('FF${hex.substring(1)}', radix: 16));
                        setDialogState(() => previewColor = color);
                      } catch (_) {}
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter a hex colour code',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.stone,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isDark ? AppColors.stone : AppColors.stone,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: previewColor,
                  foregroundColor: _contrastColor(previewColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  setState(() => _customColor = previewColor);
                  widget.onDesignUpdate(
                    widget.design.copyWith(
                      baseColor: DesignStudioUtils.colorToHex(previewColor),
                    ),
                  );
                  Navigator.pop(ctx);
                },
                child: const Text('Apply'),
              ),
            ],
          );
        },
      ),
    );
  }

  Color _contrastColor(Color bg) {
    final luminance = bg.computeLuminance();
    return luminance > 0.4 ? Colors.black : Colors.white;
  }

  Widget _buildSwatch(Color color, bool isSelected, VoidCallback onTap,
      {Widget? child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
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
                : (isDark
                    ? const Color(0xFF262B3D)
                    : const Color(0xFFE4E2DA)),
            width: isSelected ? 3 : 1.5,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: child ??
            (isSelected
                ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _contrastColor(color),
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeName = _activeName();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              // Preset fabric swatches
              ...fabrics.map((fabric) {
                final color = fabric['color'] as Color;
                final isSelected = DesignStudioUtils.isColorSelected(
                    color, widget.design.baseColor);
                return _buildSwatch(color, isSelected, () {
                  setState(() => _customColor = null);
                  widget.onDesignUpdate(
                    widget.design.copyWith(
                      baseColor: DesignStudioUtils.colorToHex(color),
                    ),
                  );
                });
              }),

              // Custom color swatch (shown after picking via "+" button)
              if (_customColor != null)
                _buildSwatch(
                  _customColor!,
                  DesignStudioUtils.isColorSelected(
                      _customColor!, widget.design.baseColor),
                  () => widget.onDesignUpdate(
                    widget.design.copyWith(
                      baseColor: DesignStudioUtils.colorToHex(_customColor!),
                    ),
                  ),
                ),

              // Rainbow "+" button — opens hex colour picker
              GestureDetector(
                onTap: _openCustomPicker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF262B3D)
                          : const Color(0xFFD0D0D0),
                      width: 1.5,
                    ),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF0000),
                        Color(0xFFFFFF00),
                        Color(0xFF00FF00),
                        Color(0xFF00FFFF),
                        Color(0xFF0000FF),
                        Color(0xFFFF00FF),
                        Color(0xFFFF0000),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
          _buildDivider(isDark),
          const SizedBox(height: 16),

          // ── Collar style ───────────────────────────────────────────────────
          _buildSectionLabel('Collar Style', isDark),
          const SizedBox(height: 10),
          _buildStyleChips(
            options: const [
              {'id': 'crew', 'label': 'Crew', 'icon': Icons.radio_button_unchecked},
              {'id': 'vneck', 'label': 'V-Neck', 'icon': Icons.change_history},
              {'id': 'polo', 'label': 'Polo', 'icon': Icons.vertical_align_bottom},
            ],
            selected: widget.design.collarStyle,
            onSelect: (id) => widget.onDesignUpdate(
              widget.design.copyWith(collarStyle: id),
            ),
            isDark: isDark,
          ),

          const SizedBox(height: 16),
          _buildDivider(isDark),
          const SizedBox(height: 16),

          // ── Pocket style ───────────────────────────────────────────────────
          _buildSectionLabel('Pocket', isDark),
          const SizedBox(height: 10),
          _buildStyleChips(
            options: const [
              {'id': 'none', 'label': 'None', 'icon': Icons.block},
              {'id': 'left', 'label': 'Left', 'icon': Icons.square_outlined},
              {'id': 'right', 'label': 'Right', 'icon': Icons.square_outlined},
              {'id': 'both', 'label': 'Both', 'icon': Icons.view_column_outlined},
            ],
            selected: widget.design.pocketStyle,
            onSelect: (id) => widget.onDesignUpdate(
              widget.design.copyWith(pocketStyle: id),
            ),
            isDark: isDark,
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) => Container(
        height: 1,
        color: isDark ? const Color(0xFF262B3D) : const Color(0xFFE8E6E0),
      );

  Widget _buildSectionLabel(String label, bool isDark) => Text(
        label.toUpperCase(),
        style: GoogleFonts.spaceMono(
          fontWeight: FontWeight.bold,
          fontSize: 11,
          color: isDark ? AppColors.stone : const Color(0xFF7A7B82),
          letterSpacing: 0.8,
        ),
      );

  Widget _buildStyleChips({
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
                    fontWeight:
                        isActive ? FontWeight.w700 : FontWeight.w500,
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
