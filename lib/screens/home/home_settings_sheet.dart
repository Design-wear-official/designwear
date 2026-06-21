import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';

/// App settings bottom-sheet matching demo settings modal.
/// Contains Appearance (light/dark) and Gallery Layout toggles.
class HomeSettingsSheet extends StatefulWidget {
  final bool isDarkMode;
  final bool isDetailLayout;
  final ValueChanged<bool> onThemeChanged;
  final ValueChanged<bool> onLayoutChanged;

  const HomeSettingsSheet({
    super.key,
    required this.isDarkMode,
    required this.isDetailLayout,
    required this.onThemeChanged,
    required this.onLayoutChanged,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isDarkMode,
    required bool isDetailLayout,
    required ValueChanged<bool> onThemeChanged,
    required ValueChanged<bool> onLayoutChanged,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => HomeSettingsSheet(
        isDarkMode: isDarkMode,
        isDetailLayout: isDetailLayout,
        onThemeChanged: onThemeChanged,
        onLayoutChanged: onLayoutChanged,
      ),
    );
  }

  @override
  State<HomeSettingsSheet> createState() => _HomeSettingsSheetState();
}

class _HomeSettingsSheetState extends State<HomeSettingsSheet> {
  late bool _isDark;
  late bool _isDetail;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDarkMode;
    _isDetail = widget.isDetailLayout;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

    return Container(
      decoration: BoxDecoration(
        color: paper,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'App Settings',
                style: GoogleFonts.archivo(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: ink,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppColors.stone, size: 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Appearance row
          _SettingRow(
            label: 'Appearance',
            description: 'Choose your viewing environment.',
            hair: hair,
            child: _SegmentedControl(
              options: const ['☀️ Bright Mode', '🌙 Dark Mode'],
              selectedIndex: _isDark ? 1 : 0,
              onChanged: (i) {
                setState(() => _isDark = i == 1);
                widget.onThemeChanged(i == 1);
              },
            ),
          ),

          const SizedBox(height: 16),

          // Layout row
          _SettingRow(
            label: 'Gallery Layout',
            description: 'Switch between a dense grid or large details.',
            hair: hair,
            isLast: true,
            child: _SegmentedControl(
              options: const ['⊞ Masonry Grid', '☰ Detail View'],
              selectedIndex: _isDetail ? 1 : 0,
              onChanged: (i) {
                setState(() => _isDetail = i == 1);
                widget.onLayoutChanged(i == 1);
              },
            ),
          ),

          const SizedBox(height: 20),

          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: ink,
                foregroundColor: paper,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String label;
  final String description;
  final Color hair;
  final Widget child;
  final bool isLast;

  const _SettingRow({
    required this.label,
    required this.description,
    required this.hair,
    required this.child,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

    return Container(
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: isLast ? BorderSide.none : BorderSide(color: hair),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: AppColors.stone,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// A pill-shaped segmented control matching demo `.app-seg`.
class _SegmentedControl extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedControl({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final card = isDark ? AppColors.cardDark : AppColors.cardLight;
    final ink = isDark ? AppColors.inkDark : AppColors.inkLight;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: paper,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: hair),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final isSelected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? card : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
                boxShadow: isSelected
                    ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))]
                    : null,
              ),
              child: Text(
                options[i],
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? ink : AppColors.stone,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
