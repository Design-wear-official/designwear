import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:designwear/presentation/styles/styles.dart';
import 'package:designwear/services/recent_emoji_service.dart';
import 'package:designwear/services/custom_sticker_service.dart';
import 'package:designwear/services/image_sanitizer.dart';

/// Stickers tab. Two modes:
///  - **Emojis**: type/paste any emoji; added emojis persist per-user via
///    [RecentEmojiService] and reappear across sessions/devices.
///  - **My Stickers**: upload custom image stickers. Uploads are validated and
///    re-encoded ([ImageSanitizer]) then stored per-user in Firebase Storage via
///    [CustomStickerService]. Tapping one places it on the canvas; long-press
///    removes it.
class StickersTab extends StatefulWidget {
  final void Function(String emoji) onAddStickerElement;
  final void Function(Uint8List pngBytes) onAddImageSticker;

  const StickersTab({
    super.key,
    required this.onAddStickerElement,
    required this.onAddImageSticker,
  });

  @override
  State<StickersTab> createState() => _StickersTabState();
}

enum _StickerMode { emoji, custom }

class _StickersTabState extends State<StickersTab> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final RecentEmojiService _emojiService = RecentEmojiService();
  final CustomStickerService _stickerService = CustomStickerService();
  final ImagePicker _picker = ImagePicker();

  _StickerMode _mode = _StickerMode.emoji;

  /// Emojis the user has added, most-recent first.
  List<String> _userEmojis = [];

  /// Uploaded custom stickers, most-recent first.
  List<CustomSticker> _customStickers = [];
  bool _loadingStickers = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedEmojis();
    _loadStickers();
  }

  Future<void> _loadSavedEmojis() async {
    final saved = await _emojiService.getRecentEmojis();
    if (!mounted) return;
    setState(() => _userEmojis = saved);
  }

  Future<void> _loadStickers() async {
    setState(() => _loadingStickers = true);
    final list = await _stickerService.getStickers();
    if (!mounted) return;
    setState(() {
      _customStickers = list;
      _loadingStickers = false;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Emoji actions ───────────────────────────────────────────────────────────

  List<String> _splitGraphemes(String input) {
    final chars = Characters(input.trim());
    return chars.where((c) => c.trim().isNotEmpty).toList();
  }

  Future<void> _submit() async {
    final emojis = _splitGraphemes(_controller.text);
    if (emojis.isEmpty) return;
    _controller.clear();
    List<String> updated = _userEmojis;
    for (final e in emojis.reversed) {
      updated = await _emojiService.addEmoji(e);
    }
    if (!mounted) return;
    setState(() => _userEmojis = updated);
    widget.onAddStickerElement(emojis.first);
    _focusNode.requestFocus();
  }

  Future<void> _removeEmoji(String emoji) async {
    final updated = await _emojiService.removeEmoji(emoji);
    if (!mounted) return;
    setState(() => _userEmojis = updated);
  }

  // ── Custom sticker actions ──────────────────────────────────────────────────

  Future<void> _uploadSticker() async {
    if (_uploading) return;
    XFile? file;
    try {
      file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 100);
    } catch (_) {
      _showMessage('Could not open the gallery.');
      return;
    }
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final raw = await file.readAsBytes();
      final png = await ImageSanitizer.sanitizeToPng(raw); // client-side block
      final sticker = await _stickerService.uploadSticker(png);
      if (!mounted) return;
      setState(() => _customStickers = [sticker, ..._customStickers]);
      widget.onAddImageSticker(png); // place immediately
    } on ImageValidationException catch (e) {
      _showMessage(e.message);
    } on CustomStickerException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Could not upload this image.');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _placeSticker(CustomSticker sticker) async {
    try {
      final res = await http.get(Uri.parse(sticker.url));
      if (res.statusCode == 200) {
        widget.onAddImageSticker(res.bodyBytes);
      } else {
        _showMessage('Could not load that sticker.');
      }
    } catch (_) {
      _showMessage('Could not load that sticker.');
    }
  }

  Future<void> _deleteSticker(CustomSticker sticker) async {
    setState(() => _customStickers.removeWhere((s) => s.id == sticker.id));
    final updated = await _stickerService.deleteSticker(sticker.id);
    if (!mounted) return;
    setState(() => _customStickers = updated);
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildModeToggle(onSurface),
        const SizedBox(height: 14),
        Expanded(
          child: _mode == _StickerMode.emoji
              ? _buildEmojiView(onSurface)
              : _buildStickerView(onSurface),
        ),
      ],
    );
  }

  Widget _buildModeToggle(Color onSurface) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final primary = Theme.of(context).colorScheme.primary;

    Widget pill(String label, _StickerMode mode) {
      final selected = _mode == mode;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _mode = mode),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: selected ? primary.withValues(alpha: 0.14) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: selected ? primary : hair),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? primary : onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill('Emojis', _StickerMode.emoji),
        const SizedBox(width: 8),
        pill('My Stickers', _StickerMode.custom),
      ],
    );
  }

  // ── Emoji view ──────────────────────────────────────────────────────────────

  Widget _buildEmojiView(Color onSurface) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type or paste any emoji to add it to your design.',
          style: GoogleFonts.outfit(fontSize: 11, color: onSurface.withValues(alpha: 0.6)),
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
                  hintStyle: TextStyle(fontSize: 18, color: onSurface.withValues(alpha: 0.35)),
                  filled: true,
                  fillColor: paper,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: hair),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _userEmojis.isEmpty
              ? _emptyHint('No emojis yet.\nAdd one above to get started.', onSurface)
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: _userEmojis.length,
                  itemBuilder: (context, index) {
                    final sticker = _userEmojis[index];
                    return GestureDetector(
                      onTap: () => widget.onAddStickerElement(sticker),
                      onLongPress: () => _removeEmoji(sticker),
                      child: Container(
                        decoration: BoxDecoration(
                          color: paper,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: hair),
                        ),
                        child: Center(child: Text(sticker, style: const TextStyle(fontSize: 22))),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ── Custom sticker view ─────────────────────────────────────────────────────

  Widget _buildStickerView(Color onSurface) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paper = isDark ? AppColors.paperDark : AppColors.paperLight;
    final hair = isDark ? AppColors.hairDark : AppColors.hairLight;
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _uploading ? null : _uploadSticker,
            icon: _uploading
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.upload_outlined, size: 18),
            label: Text(_uploading ? 'Uploading…' : 'Upload sticker',
                style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 13)),
            style: OutlinedButton.styleFrom(
              foregroundColor: primary,
              side: BorderSide(color: primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'PNG, JPEG, WebP or GIF · max 2 MB. Sign in to save them.',
          style: GoogleFonts.outfit(fontSize: 10, color: onSurface.withValues(alpha: 0.55)),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loadingStickers
              ? const Center(child: CircularProgressIndicator())
              : _customStickers.isEmpty
                  ? _emptyHint('No custom stickers yet.\nUpload one above.', onSurface)
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                      ),
                      itemCount: _customStickers.length,
                      itemBuilder: (context, index) {
                        final sticker = _customStickers[index];
                        return GestureDetector(
                          onTap: () => _placeSticker(sticker),
                          onLongPress: () => _deleteSticker(sticker),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: paper,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: hair),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: sticker.url,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => const Center(
                                child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                              errorWidget: (_, __, ___) =>
                                  Icon(Icons.broken_image_outlined, color: onSurface.withValues(alpha: 0.4)),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _emptyHint(String text, Color onSurface) => Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 12, color: onSurface.withValues(alpha: 0.5)),
        ),
      );
}
