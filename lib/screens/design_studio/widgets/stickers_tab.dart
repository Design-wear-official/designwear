import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:designwear/presentation/styles/styles.dart';

/// Stickers tab — users add their OWN emojis. We don't ship a preset list.
///
/// The user types or pastes an emoji into the field and adds it. Emojis added
/// this session are kept for quick re-use; tapping one places it on the canvas.
class StickersTab extends StatefulWidget {
  final Function(String) onAddStickerElement;

  const StickersTab({super.key, required this.onAddStickerElement});

  @override
  State<StickersTab> createState() => _StickersTabState();
}

class _StickersTabState extends State<StickersTab> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  /// Emojis the user has added this session, most-recent first.
  final List<String> _userEmojis = [];

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Extract grapheme clusters (handles multi-codepoint emoji like 👨‍👩‍👧).
  List<String> _splitGraphemes(String input) {
    final chars = Characters(input.trim());
    return chars.where((c) => c.trim().isNotEmpty).toList();
  }

  void _submit() {
    final emojis = _splitGraphemes(_controller.text);
    if (emojis.isEmpty) return;
    setState(() {
      for (final e in emojis) {
        _userEmojis.remove(e); // de-dupe, move to front
        _userEmojis.insert(0, e);
      }
      _controller.clear();
    });
    // Add the first one straight to the canvas for immediate feedback.
    widget.onAddStickerElement(emojis.first);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'YOUR EMOJIS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            letterSpacing: 1.0,
            color: onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Type or paste any emoji to add it to your design.',
          style: GoogleFonts.outfit(
            fontSize: 11,
            color: onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 22),
                onSubmitted: (_) => _submit(),
                inputFormatters: [LengthLimitingTextInputFormatter(40)],
                decoration: InputDecoration(
                  hintText: '😀 🔥 ⭐',
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: onSurface.withValues(alpha: 0.35),
                  ),
                  filled: true,
                  fillColor: paper,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: hair),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              child: FilledButton(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _userEmojis.isEmpty
              ? Center(
                  child: Text(
                    'No emojis yet.\nAdd one above to get started.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                )
              : GridView.builder(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: _userEmojis.length,
                  itemBuilder: (context, index) {
                    final sticker = _userEmojis[index];
                    return GestureDetector(
                      onTap: () => widget.onAddStickerElement(sticker),
                      onLongPress: () =>
                          setState(() => _userEmojis.removeAt(index)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: hair),
                        ),
                        child: Center(
                          child: Text(sticker,
                              style: const TextStyle(fontSize: 22)),
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
