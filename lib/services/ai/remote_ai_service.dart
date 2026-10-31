import 'dart:convert';

import '../../api/api_client.dart';
import 'ai_service.dart';

/// AI through the DesignWear API, which holds the model keys.
class RemoteAiService implements AiService {
  RemoteAiService(this._api, this.features);

  final ApiClient _api;
  final ServerFeatures features;

  /// A one-time pass the server hands back with a design edit; it covers that
  /// design's graphic, so a design and its picture count as one creation.
  String? _imagePass;

  @override
  bool get isConfigured => features.designAgent || features.tryOn;

  @override
  bool get agentEnabled => features.designAgent;

  @override
  bool get tryOnEnabled => features.tryOn;

  @override
  Future<List<int>> tryOn({
    required List<int> personPhoto,
    String? productId,
    List<int>? garmentImage,
    String? title,
  }) async {
    try {
      final j = await _api.request(
        'POST',
        '/v1/ai/try-on',
        body: {
          'photo': base64Encode(personPhoto),
          if (garmentImage != null)
            'garment': base64Encode(garmentImage)
          else
            'productId': productId,
          'title': ?title,
        },
        timeout: const Duration(seconds: 120),
      );
      return base64Decode('${j['image']}');
    } on ApiException catch (e) {
      if (e.status == 503) throw const AiUnavailable();
      throw AiFailure(e.message);
    }
  }

  @override
  Future<({String text, Map<String, Object?>? design})> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
  }) async {
    try {
      final j = await _api.request(
        'POST',
        '/v1/ai/design-agent',
        body: {
          'message': message,
          'design': design,
          'history': [
            for (final m in history)
              {'role': m.fromUser ? 'user' : 'assistant', 'content': m.text},
          ],
          'images': [for (final i in images) base64Encode(i)],
        },
        timeout: const Duration(seconds: 90),
      );
      _imagePass = j['imagePass'] as String?;
      return (
        text: '${j['text']}',
        design: (j['design'] as Map?)?.cast<String, Object?>(),
      );
    } on ApiException catch (e) {
      if (e.status == 503) throw const AiUnavailable();
      throw AiFailure(e.message);
    }
  }

  @override
  Future<List<int>> designImage(String prompt) async {
    try {
      final pass = _imagePass;
      _imagePass = null; // good for one picture
      final j = await _api.post('/v1/ai/design-image', {
        'prompt': prompt,
        'pass': ?pass,
      });
      return base64Decode('${j['image']}');
    } on ApiException catch (e) {
      if (e.status == 503) throw const AiUnavailable();
      throw AiFailure(e.message);
    }
  }
}
