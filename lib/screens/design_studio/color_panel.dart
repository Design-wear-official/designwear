import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<String> _recents = [];

  static const String _recentsKey = 'ds_recent_colors';
  static const int _maxRecents = 8;

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

  // Accent colours offered for collar / pocket / cuff trim.
  static const List<Color> trimSwatches = [
    Color(0xFF111111), // Black
    Color(0xFFFFFFFF), // White
    Color(0xFFC9A227), // Gold
    Color(0xFF1A1F3C), // Navy
    Color(0xFFDC143C), // Crimson
    Color(0xFF2D5A27), // Forest
    Color(0xFFFF6B35), // Coral
    Color(0xFF475569), // Slate
  ];

  // Curated quick palettes — tap any dot to apply it as the fabric colour.
  static const List<Map<String, dynamic>> palettes = [
    {
      'name': 'Mono',
      'colors': [
        Color(0xFFFFFFFF),
        Color(0xFFCBCBCB),
        Color(0xFF8A8A8A),
        Color(0xFF2B2E33),
        Color(0xFF111111),
      ],
    },
    {
      'name': 'Earth',
      'colors': [
        Color(0xFFF4D99C),
        Color(0xFFC19A6B),
        Color(0xFFB65D3C),
        Color(0xFF6B7C3E),
        Color(0xFF3C1F0F),
      ],
    },
    {
      'name': 'Neon',
      'colors': [
        Color(0xFFFF1493),
        Color(0xFFFF6B35),
        Color(0xFFF59E0B),
        Color(0xFF32CD32),
        Color(0xFF00CED1),
      ],
    },
    {
      'name': 'Pastel',
      'colors': [
        Color(0xFFFFB6C1),
        Color(0xFFFFCBA4),
        Color(0xFF8FC9A2),
        Color(0xFF87BFDC),
        Color(0xFFC8B8E0),
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadRecents();
  }

  Future<void> _loadRecents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_recentsKey);
      if (stored != null && mounted) setState(() => _recents = stored);
    } catch (_) {}
  }

  /// Applies [color] as the fabric base colour and records it as recent.
  void _applyBase(Color color, {bool fromCustom = false}) {
    setState(() => _customColor = fromCustom ? color : null);
    widget.onDesignUpdate(
      widget.design.copyWith(baseColor: DesignStudioUtils.colorToHex(color)),
    );
    _pushRecent(color);
  }

  Future<void> _pushRecent(Color color) async {
    final hex = DesignStudioUtils.colorToHex(color);
    final next = [hex, ..._recents.where((c) => c != hex)].take(_maxRecents).toList();
    setState(() => _recents = next);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_recentsKey, next);
    } catch (_) {}
  }

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
    return 'Custom';
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
                  _applyBase(previewColor, fromCustom: true);
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
      {Widget? child, double size = 36}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor =
        isSelected ? AppColors.dsAccent : AppColors.dsBorder(isDark);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size.isFinite ? size : null,
        height: size.isFinite ? size : null,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.dsBarBg(isDark),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: ringColor,
              spreadRadius: 2,
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
            'TEE COLOUR — $activeName',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              fontSize: 12,
              color: AppColors.dsTextSecondary(isDark),
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1,
            children: [
              // Preset fabric swatches
              ...fabrics.map((fabric) {
                final color = fabric['color'] as Color;
                final isSelected = DesignStudioUtils.isColorSelected(
                    color, widget.design.baseColor);
                return _buildSwatch(color, isSelected, () => _applyBase(color), size: double.infinity);
              }),

              // Custom color swatch (shown after picking via "+" button)
              if (_customColor != null)
                _buildSwatch(
                  _customColor!,
                  DesignStudioUtils.isColorSelected(
                      _customColor!, widget.design.baseColor),
                  () => _applyBase(_customColor!, fromCustom: true),
                  size: double.infinity,
                ),

              // Rainbow "+" button — opens hex colour picker
              GestureDetector(
                onTap: _openCustomPicker,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.dsBorder(isDark),
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

          // ── Recently used ──────────────────────────────────────────────────
          if (_recents.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildDivider(isDark),
            const SizedBox(height: 16),
            _buildSectionLabel('Recently used', isDark),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _recents.map((hex) {
                final color = DesignStudioUtils.parseColorFromHex(hex);
                final isSelected = DesignStudioUtils.isColorSelected(
                    color, widget.design.baseColor);
                return _buildSwatch(
                    color, isSelected, () => _applyBase(color), size: 30);
              }).toList(),
            ),
          ],

          // ── Quick palettes ─────────────────────────────────────────────────
          const SizedBox(height: 20),
          _buildDivider(isDark),
          const SizedBox(height: 16),
          _buildSectionLabel('Quick palettes', isDark),
          const SizedBox(height: 10),
          ...palettes.map((p) => _buildPaletteRow(p, isDark)),

          // ── Trim / accent ──────────────────────────────────────────────────
          const SizedBox(height: 16),
          _buildDivider(isDark),
          const SizedBox(height: 16),
          _buildSectionLabel('Trim / Accent', isDark),
          const SizedBox(height: 10),
          _buildTrimRow(isDark),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildPaletteRow(Map<String, dynamic> palette, bool isDark) {
    final name = palette['name'] as String;
    final colors = palette['colors'] as List<Color>;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.stone : const Color(0xFF7A7B82),
              ),
            ),
          ),
          const SizedBox(width: 4),
          ...colors.map((c) {
            final isSelected =
                DesignStudioUtils.isColorSelected(c, widget.design.baseColor);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildSwatch(c, isSelected, () => _applyBase(c), size: 26),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTrimRow(bool isDark) {
    final isAuto = widget.design.trimColor == 'auto';
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // "Auto" pill — derives a contrasting shade from the fabric colour.
        GestureDetector(
          onTap: () => widget.onDesignUpdate(
            widget.design.copyWith(trimColor: 'auto'),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isAuto
                  ? (isDark ? Colors.white : const Color(0xFF15182B))
                  : (isDark
                      ? const Color(0xFF1A1F2E)
                      : const Color(0xFFF2F1ED)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isAuto
                    ? Colors.transparent
                    : (isDark
                        ? const Color(0xFF262B3D)
                        : const Color(0xFFDDDBD5)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_fix_high,
                    size: 13,
                    color: isAuto
                        ? (isDark ? const Color(0xFF15182B) : Colors.white)
                        : (isDark ? AppColors.stone : const Color(0xFF7A7B82))),
                const SizedBox(width: 5),
                Text(
                  'Auto',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: isAuto ? FontWeight.w700 : FontWeight.w500,
                    color: isAuto
                        ? (isDark ? const Color(0xFF15182B) : Colors.white)
                        : (isDark ? AppColors.stone : const Color(0xFF7A7B82)),
                  ),
                ),
              ],
            ),
          ),
        ),
        ...trimSwatches.map((c) {
          final isSelected = !isAuto &&
              DesignStudioUtils.isColorSelected(c, widget.design.trimColor);
          return _buildSwatch(
            c,
            isSelected,
            () => widget.onDesignUpdate(
              widget.design
                  .copyWith(trimColor: DesignStudioUtils.colorToHex(c)),
            ),
            size: 30,
          );
        }),
      ],
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
}
