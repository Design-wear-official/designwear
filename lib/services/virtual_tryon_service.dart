import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:designwear/config/config.dart';

/// Service to handle Virtual Try-On using the local Node API proxy
class VirtualTryOnService {
  String get _baseUrl =>
      ConfigLoader.get('WEB_API_BASE_URL') ?? 'https://designwear-backend.vishwamai.com/api';

  /// Generate a virtual try-on image
  Future<Uint8List?> generateTryOn({
    required Uint8List personImageBytes,
    required Uint8List clothingImageBytes,
  }) async {
    try {
      final personBase64 = base64Encode(personImageBytes);
      final clothingBase64 = base64Encode(clothingImageBytes);

      final response = await http.post(
        Uri.parse('$_baseUrl/ai/try-on'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'personImageBase64': personBase64,
          'clothingImageBase64': clothingBase64,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final generatedBase64 = responseData['generateImageBase64'];
        if (generatedBase64 != null) {
          return base64Decode(generatedBase64);
        }
        throw VirtualTryOnException('No image returned from backend API');
      } else {
        throw VirtualTryOnException('API Error: ${responseData['error']}');
      }
    } catch (e) {
      if (e is VirtualTryOnException) rethrow;
      throw VirtualTryOnException('Failed to generate try-on: $e');
    }
  }

  Future<File> saveImage(Uint8List imageBytes, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(imageBytes);
    return file;
  }

  Future<Uint8List> fileToBytes(File file) async {
    return await file.readAsBytes();
  }

  bool get isConfigured => true; // API assumes backend is always configured
}

class VirtualTryOnException implements Exception {
  final String message;
  VirtualTryOnException(this.message);

  @override
  String toString() => message;
}
