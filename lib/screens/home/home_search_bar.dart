import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Reusable premium search bar used in the home app bar.
class HomeSearchBar extends StatelessWidget {
  final bool isDesktop;
  final bool isDark;
  final bool searchFocused;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;

  const HomeSearchBar({
    super.key,
    required this.isDesktop,
    required this.isDark,
    required this.searchFocused,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
  });

  static const Color _green = Color(0xFF22C55E);
  static const Color _greenDim = Color(0xFF1EA04A);

  @override
  Widget build(BuildContext context) {
    const double barH = 46.0;
    final bgColor = isDark ? const Color(0xFF2A2A2E) : Colors.white;
    final borderColor = searchFocused ? _green : _greenDim;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      height: barH,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(barH / 2),
        border: Border.all(color: borderColor, width: searchFocused ? 2.0 : 1.8),
        boxShadow: searchFocused
            ? [BoxShadow(color: _green.withOpacity(0.22), blurRadius: 14, spreadRadius: 1, offset: const Offset(0, 2))]
            : isDark
                ? [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))]
                : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 1))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Search icon
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 8),
            child: Icon(
              Icons.search_rounded,
              size: 20,
              color: searchFocused
                  ? _green
                  : (isDark ? const Color(0xFFB0B3BA) : const Color(0xFF9E9E9E)),
            ),
          ),

          // Input
          Expanded(
            child: TextField(
              focusNode: focusNode,
              controller: controller,
              style: GoogleFonts.outfit(
                fontSize: 14.5,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFE8E8EC) : Colors.black87,
                height: 1.2,
              ),
              textAlignVertical: TextAlignVertical.center,
              textInputAction: TextInputAction.search,
              cursorColor: _green,
              cursorWidth: 2,
              cursorHeight: 18,
              decoration: InputDecoration(
                hintText: isDesktop ? 'Search products, designs, categories…' : 'Search products and designs…',
                hintStyle: GoogleFonts.outfit(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w400,
                  color: isDark ? const Color(0xFF7A7D85) : const Color(0xFF9CA3AF),
                  height: 1.2,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.only(bottom: 1),
                isDense: true,
              ),
              onSubmitted: (_) => onSearch(),
              onChanged: (_) => (context as Element).markNeedsBuild(),
            ),
          ),

          // Clear button
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                (context as Element).markNeedsBuild();
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close_rounded, size: 13, color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            )
          else
            const SizedBox(width: 12),

          // Desktop search pill
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 5),
              child: GestureDetector(
                onTap: onSearch,
                child: Container(
                  height: barH - 10,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: _green,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: _green.withOpacity(0.35), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Search',
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

