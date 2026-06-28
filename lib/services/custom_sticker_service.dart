import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:designwear/config/config.dart';

/// A user-uploaded custom sticker stored in Firebase Storage, keyed per user.
class CustomSticker {
  final String id;
  final String url;
  final String contentType;

  CustomSticker({required this.id, required this.url, required this.contentType});

  factory CustomSticker.fromJson(Map<String, dynamic> j) => CustomSticker(
        id: j['id'] as String,
        url: j['url'] as String,
        contentType: (j['contentType'] as String?) ?? 'image/png',
      );
}

/// Raised when an upload/delete fails. [message] is safe to show to the user.
class CustomStickerException implements Exception {
  final String message;
  const CustomStickerException(this.message);
  @override
  String toString() => message;
}

/// Per-user custom sticker library backed by the `/api/user/stickers` endpoint
/// (Firebase Storage + Firestore `userStickers/{uid}`). Requires sign-in; for
/// guests every call is a no-op returning an empty list.
class CustomStickerService {
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
      debugPrint('CustomStickerService: failed to get ID token: $e');
      return null;
    }
  }

  List<CustomSticker> _parseList(Map<String, dynamic> body) {
    final data = body['data'] as Map<String, dynamic>?;
    final list = (data?['stickers'] as List?) ?? [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(CustomSticker.fromJson)
        .toList();
  }

  /// Returns the signed-in user's stickers (most-recent first), or [] for guests.
  Future<List<CustomSticker>> getStickers() async {
    final base = _baseUrl;
    final headers = await _authHeaders();
    if (base == null || headers == null) return [];
    try {
      final res = await http
          .get(Uri.parse('$base/user/stickers'), headers: headers)
          .timeout(WebApiConfig.timeout);
      if (res.statusCode != 200) return [];
      return _parseList(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('CustomStickerService: list failed: $e');
      return [];
    }
  }

  /// Uploads already-sanitized PNG [pngBytes]. Returns the created sticker, or
  /// throws [CustomStickerException] with a user-facing message.
  Future<CustomSticker> uploadSticker(Uint8List pngBytes) async {
    final base = _baseUrl;
    final headers = await _authHeaders();
    if (base == null || headers == null) {
      throw const CustomStickerException('Please sign in to upload stickers.');
    }
    http.Response res;
    try {
      res = await http
          .post(
            Uri.parse('$base/user/stickers'),
            headers: headers,
            body: jsonEncode({'imageBase64': base64Encode(pngBytes)}),
          )
          .timeout(WebApiConfig.timeout);
    } catch (e) {
      throw const CustomStickerException('Upload failed. Check your connection.');
    }
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['success'] != true) {
      throw CustomStickerException(
          (body['error'] as String?) ?? 'Upload failed (${res.statusCode}).');
    }
    return CustomSticker.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Deletes a sticker by [id]. Returns the updated list (falls back to a fresh
  /// fetch on partial failure).
  Future<List<CustomSticker>> deleteSticker(String id) async {
    final base = _baseUrl;
    final headers = await _authHeaders();
    if (base == null || headers == null) return [];
    try {
      final res = await http
          .delete(Uri.parse('$base/user/stickers?id=$id'), headers: headers)
          .timeout(WebApiConfig.timeout);
      if (res.statusCode != 200) return getStickers();
      return _parseList(jsonDecode(res.body) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('CustomStickerService: delete failed: $e');
      return getStickers();
    }
  }
}
