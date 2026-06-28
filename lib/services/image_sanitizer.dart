import 'dart:typed_data';
import 'dart:ui' as ui;

/// Raised when an uploaded file fails the safety checks. [message] is safe to
/// show to the user.
class ImageValidationException implements Exception {
  final String message;
  const ImageValidationException(this.message);
  @override
  String toString() => message;
}

/// Client-side half of the malicious-upload block.
///
/// Validates that bytes are a *real* raster image of an allowed type (by magic
/// bytes, not file extension), enforces size and dimension caps, then decodes
/// and **re-encodes to a clean PNG** — which strips any embedded metadata,
/// scripts, or trailing payloads. SVG and anything non-raster is rejected
/// because it can carry executable content (stored XSS).
class ImageSanitizer {
  static const int maxBytes = 2 * 1024 * 1024; // 2 MB
  static const int maxDimension = 1600; // px (longest side)

  static Future<Uint8List> sanitizeToPng(Uint8List input) async {
    if (input.lengthInBytes == 0) {
      throw const ImageValidationException('The file is empty.');
    }
    if (input.lengthInBytes > maxBytes) {
      throw const ImageValidationException('Image is too large (max 2 MB).');
    }
    if (!_isAllowedRaster(input)) {
      throw const ImageValidationException(
        'Unsupported or unsafe file. Use a PNG, JPEG, WebP, or GIF image.',
      );
    }

    ui.Image image;
    try {
      // Probe dimensions first.
      final probe = await ui.instantiateImageCodec(input);
      final probeFrame = await probe.getNextFrame();
      final w = probeFrame.image.width;
      final h = probeFrame.image.height;
      probeFrame.image.dispose();
      probe.dispose();

      if (w <= 0 || h <= 0) {
        throw const ImageValidationException('Image has invalid dimensions.');
      }

      // Re-decode, downscaling if either side exceeds the cap.
      if (w > maxDimension || h > maxDimension) {
        final scale = maxDimension / (w > h ? w : h);
        final codec = await ui.instantiateImageCodec(
          input,
          targetWidth: (w * scale).round(),
          targetHeight: (h * scale).round(),
        );
        image = (await codec.getNextFrame()).image;
        codec.dispose();
      } else {
        final codec = await ui.instantiateImageCodec(input);
        image = (await codec.getNextFrame()).image;
        codec.dispose();
      }
    } on ImageValidationException {
      rethrow;
    } catch (_) {
      throw const ImageValidationException('Could not read this image.');
    }

    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (byteData == null) {
      throw const ImageValidationException('Could not process this image.');
    }
    return byteData.buffer.asUint8List();
  }

  /// Magic-byte check for the allowed raster formats. Mirrors the server.
  static bool _isAllowedRaster(Uint8List b) {
    if (b.length < 12) return false;
    // PNG: 89 50 4E 47
    if (b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4E && b[3] == 0x47) return true;
    // JPEG: FF D8 FF
    if (b[0] == 0xFF && b[1] == 0xD8 && b[2] == 0xFF) return true;
    // GIF: 47 49 46 38
    if (b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x38) return true;
    // WebP: "RIFF" .... "WEBP"
    if (b[0] == 0x52 && b[1] == 0x49 && b[2] == 0x46 && b[3] == 0x46 &&
        b[8] == 0x57 && b[9] == 0x45 && b[10] == 0x42 && b[11] == 0x50) {
      return true;
    }
    return false;
  }
}
