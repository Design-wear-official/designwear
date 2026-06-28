import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:designwear/config/config.dart';

/// Persists the emojis a user adds in the Design Studio's Stickers tab.
///
/// Storage strategy (per-user cloud, with offline cache):
///  - When the user is signed in and the web API is enabled, the canonical list
///    lives in the backend (Firestore `userEmojis/{uid}`), so it syncs across
///    devices.
///  - A local [SharedPreferences] copy is always kept as an offline cache and as
///    the sole store for guests / when the API is unavailable.
///
/// The list is ordered most-recent first and capped at [_maxEmojis].
class RecentEmojiService {
  static const String _cacheKey = 'recent_user_emojis';
  static const int _maxEmojis = 60;

  String? get _baseUrl => WebApiConfig.useWebApi ? WebApiConfig.baseUrl : null;

  Future<Map<String, String>?> _authHeaders() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    try {
      final idToken = await user.getIdToken();
      if (idToken == null || idToken.isEmpty) return null;
      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $idToken',
      };
    } catch (e) {
      debugPrint('RecentEmojiService: failed to get ID token: $e');
      return null;
    }
  }

  // ── Local cache ─────────────────────────────────────────────────────────────

  Future<List<String>> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_cacheKey) ?? [];
  }

  Future<void> _writeCache(List<String> emojis) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_cacheKey, emojis);
  }

  // ── Cloud sync ──────────────────────────────────────────────────────────────

  /// Pulls the list from the backend. Returns null if unavailable (not signed
  /// in, API disabled, or request failed) so callers can fall back to cache.
  Future<List<String>?> _fetchCloud() async {
    final base = _baseUrl;
    final headers = await _authHeaders();
    if (base == null || headers == null) return null;
    try {
      final res = await http
          .get(Uri.parse('$base/user/emojis'), headers: headers)
          .timeout(WebApiConfig.timeout);
      if (res.statusCode != 200) return null;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final data = body['data'] as Map<String, dynamic>?;
      final list = (data?['emojis'] as List?)?.cast<String>() ?? [];
      return list;
    } catch (e) {
      debugPrint('RecentEmojiService: cloud fetch failed: $e');
      return null;
    }
  }

  /// Best-effort push of the full list to the backend.
  Future<void> _pushCloud(List<String> emojis) async {
    final base = _baseUrl;
    final headers = await _authHeaders();
    if (base == null || headers == null) return;
    try {
      await http
          .put(
            Uri.parse('$base/user/emojis'),
            headers: headers,
            body: jsonEncode({'emojis': emojis}),
          )
          .timeout(WebApiConfig.timeout);
    } catch (e) {
      debugPrint('RecentEmojiService: cloud push failed: $e');
    }
  }

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Returns the user's saved emojis, most-recent first.
  ///
  /// Prefers the cloud list (and refreshes the local cache with it); falls back
  /// to the local cache when offline or for guests.
  Future<List<String>> getRecentEmojis() async {
    final cloud = await _fetchCloud();
    if (cloud != null) {
      await _writeCache(cloud);
      return cloud;
    }
    return _readCache();
  }

  /// Adds [emoji] to the front (de-duped), persists locally and to the cloud.
  /// Returns the updated list.
  Future<List<String>> addEmoji(String emoji) async {
    final emojis = await _readCache();
    emojis.remove(emoji); // de-dupe, move to front
    emojis.insert(0, emoji);
    if (emojis.length > _maxEmojis) {
      emojis.removeRange(_maxEmojis, emojis.length);
    }
    await _writeCache(emojis);
    await _pushCloud(emojis);
    return emojis;
  }

  /// Removes [emoji], persists locally and to the cloud. Returns the updated list.
  Future<List<String>> removeEmoji(String emoji) async {
    final emojis = await _readCache();
    emojis.remove(emoji);
    await _writeCache(emojis);
    await _pushCloud(emojis);
    return emojis;
  }
}
