import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

/// Phone and desktop apps: the share sheet is how a picture is saved ("Save image", "Save to files").
Future<bool> savePng(Uint8List bytes, String name) async {
  final result = await SharePlus.instance.share(
    ShareParams(
      files: [XFile.fromData(bytes, mimeType: 'image/png', name: name)],
      fileNameOverrides: [name],
    ),
  );
  return result.status != ShareResultStatus.unavailable;
}
