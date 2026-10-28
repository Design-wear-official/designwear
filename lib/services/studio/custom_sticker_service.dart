import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

import '../../logging/app_log.dart';

/// A user-uploaded sticker kept on this device.
class CustomSticker {
  final String id;
  final Uint8List bytes;
  CustomSticker({required this.id, required this.bytes});
}

/// Raised when an upload fails. [message] is safe to show to the user.
class CustomStickerException implements Exception {
  final String message;
  const CustomStickerException(this.message);
  @override
  String toString() => message;
}

/// Personal sticker library, stored on this device (images are sanitised to
/// PNG before they get here). Capped so it can't fill local storage.
class CustomStickerService {
  static const _key = 'studio.stickers.v1';
  static const maxStickers = 12;
  static const maxBytes = 300 * 1024;

  Future<List<CustomSticker>> getStickers() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(_key);
      if (raw == null) return [];
      return [
        for (final e in (jsonDecode(raw) as List))
          CustomSticker(
            id: '${(e as Map)['id']}',
            bytes: base64Decode('${e['data']}'),
          ),
      ];
    } catch (e) {
      AppLog.instance.warning('stickers', 'Could not read stickers', e);
      return [];
    }
  }

  Future<void> _write(List<CustomSticker> list) async {
    await (await SharedPreferences.getInstance()).setString(
      _key,
      jsonEncode([
        for (final s in list) {'id': s.id, 'data': base64Encode(s.bytes)},
      ]),
    );
  }

  Future<CustomSticker> uploadSticker(Uint8List pngBytes) async {
    if (pngBytes.length > maxBytes) {
      throw const CustomStickerException(
        'That image is too large for a sticker (max 300 KB).',
      );
    }
    final list = await getStickers();
    if (list.length >= maxStickers) {
      throw const CustomStickerException(
        'Sticker library is full. Long-press one to delete it.',
      );
    }
    final sticker = CustomSticker(
      id: DateTime.now().microsecondsSinceEpoch.toRadixString(36),
      bytes: pngBytes,
    );
    try {
      await _write([sticker, ...list]);
    } catch (_) {
      throw const CustomStickerException(
        'Could not save the sticker on this device.',
      );
    }
    return sticker;
  }

  Future<List<CustomSticker>> deleteSticker(String id) async {
    final list = (await getStickers()).where((s) => s.id != id).toList();
    try {
      await _write(list);
    } catch (_) {}
    return list;
  }
}
