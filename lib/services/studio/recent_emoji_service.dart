import 'package:shared_preferences/shared_preferences.dart';

/// The emojis a person has used (or saved) in the studio, most recent first.
/// Kept on this device.
class RecentEmojiService {
  static const String _cacheKey = 'recent_user_emojis';
  static const int _maxEmojis = 60;

  Future<List<String>> _read() async {
    try {
      return (await SharedPreferences.getInstance()).getStringList(_cacheKey) ??
          [];
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(List<String> emojis) async {
    try {
      await (await SharedPreferences.getInstance()).setStringList(
        _cacheKey,
        emojis,
      );
    } catch (_) {}
  }

  Future<List<String>> getRecentEmojis() => _read();

  /// Adds [emoji] to the front (de-duped). Returns the updated list.
  Future<List<String>> addEmoji(String emoji) async {
    final emojis = await _read();
    emojis.remove(emoji);
    emojis.insert(0, emoji);
    if (emojis.length > _maxEmojis) {
      emojis.removeRange(_maxEmojis, emojis.length);
    }
    await _write(emojis);
    return emojis;
  }

  Future<List<String>> removeEmoji(String emoji) async {
    final emojis = await _read()
      ..remove(emoji);
    await _write(emojis);
    return emojis;
  }
}
