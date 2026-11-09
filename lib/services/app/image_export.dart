// Saving and sharing a picture the app made (the try-on result).
//
// The web downloads a PNG straight from the browser; the phone and desktop apps open the system share
// sheet, whose "Save image" / "Save to files" does the saving there.
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'image_export_stub.dart'
    if (dart.library.js_interop) 'image_export_web.dart'
    as platform;

class ImageExport {
  ImageExport._();

  /// Saves [bytes] as a PNG called [name]. Returns false when nothing could be saved.
  static Future<bool> download(Uint8List bytes, String name) async {
    try {
      return await platform.savePng(bytes, name);
    } catch (_) {
      return false;
    }
  }

  /// Opens the system share sheet with the picture. Returns false when sharing is not available.
  static Future<bool> share(
    Uint8List bytes,
    String name, {
    String? text,
  }) async {
    try {
      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile.fromData(bytes, mimeType: 'image/png', name: name)],
          fileNameOverrides: [name],
          text: text,
        ),
      );
      return result.status != ShareResultStatus.unavailable;
    } catch (_) {
      return false;
    }
  }
}
