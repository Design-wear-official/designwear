import 'dart:convert';

import '../../api/api_client.dart';
import 'ai_service.dart';
import 'layers.dart';

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
  bool get trendsEnabled => features.trends && features.designAgent;

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
  Future<TryOnViews> tryOnViews({
    required List<int> personPhoto,
    required Map<String, List<int>> views,
    String? title,
  }) async {
    try {
      final j = await _api.request(
        'POST',
        '/v1/ai/try-on',
        body: {
          'photo': base64Encode(personPhoto),
          'views': [
            for (final e in views.entries)
              {'side': e.key, 'garment': base64Encode(e.value)},
          ],
          'title': ?title,
        },
        // One picture per angle, made one after the other.
        timeout: const Duration(seconds: 240),
      );
      final drawn = (j['images'] as Map?)?.cast<String, Object?>() ?? const {};
      final images = {
        for (final e in drawn.entries)
          if ('${e.value}'.isNotEmpty) e.key: base64Decode('${e.value}'),
      };
      if (images.isEmpty && '${j['image'] ?? ''}'.isNotEmpty) {
        images['front'] = base64Decode('${j['image']}');
      }
      return TryOnViews(
        images: images,
        failed: [for (final f in (j['failed'] as List? ?? const [])) '$f'],
      );
    } on ApiException catch (e) {
      if (e.status == 503) throw const AiUnavailable();
      throw AiFailure(e.message);
    }
  }

  @override
  Future<DesignAgentReply> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
    bool trends = false,
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
          if (trends) 'trends': true,
        },
        timeout: const Duration(seconds: 90),
      );
      _imagePass = j['imagePass'] as String?;
      final t = (j['trends'] as Map?)?.cast<String, Object?>();
      return DesignAgentReply(
        text: '${j['text']}',
        design: (j['design'] as Map?)?.cast<String, Object?>(),
        art: (j['art'] as String?)?.trim().isEmpty ?? true
            ? null
            : (j['art'] as String).trim(),
        trends: t == null
            ? null
            : TrendsInfo(
                asOf: '${t['asOf']}',
                sources: [
                  for (final s in (t['sources'] as List? ?? const []))
                    if (s is Map && '${s['url']}'.startsWith('https://'))
                      (title: '${s['title'] ?? ''}', url: '${s['url']}'),
                ],
              ),
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

  @override
  Future<LayerJob> designLayers(
    String prompt, {
    List<List<int>> images = const [],
    String? garment,
    String? color,
    String? name,
    String? size,
    List<String> sides = const ['front', 'back', 'left', 'right'],
  }) async {
    final pass = _imagePass;
    try {
      _imagePass = null; // one creation, however many sides
      final j = await _api.request(
        'POST',
        '/v1/ai/design-layers',
        body: {
          'prompt': prompt,
          'sides': sides,
          'pass': ?pass,
          'garment': ?garment,
          'color': ?color,
          'size': ?size,
          if (name != null && name.isNotEmpty) 'name': name,
          if (images.isNotEmpty)
            'images': [for (final i in images.take(3)) base64Encode(i)],
        },
        timeout: const Duration(seconds: 120),
      );
      return LayerJob.fromJson(j.cast<String, dynamic>());
    } on ApiException catch (e) {
      if (e.status == 404) {
        _imagePass = pass; // the fallback route can still use it
        throw const LayersUnsupported();
      }
      if (e.status == 503) throw const AiUnavailable();
      throw AiFailure(e.message);
    }
  }

  @override
  Future<List<int>> fetchLayerImage(String url) async {
    try {
      return await _api.getBytes(url);
    } on ApiException catch (e) {
      throw AiFailure(e.message);
    }
  }

  @override
  Future<DesignSides> designSides(
    String prompt, {
    List<List<int>> images = const [],
  }) async {
    try {
      final pass = _imagePass;
      _imagePass = null; // one pass covers all the faces
      final j = await _api.request(
        'POST',
        '/v1/ai/design-sides',
        body: {
          'prompt': prompt,
          'pass': ?pass,
          if (images.isNotEmpty)
            'images': [for (final i in images) base64Encode(i)],
        },
        timeout: const Duration(seconds: 100),
      );
      final drawn = (j['images'] as Map?)?.cast<String, Object?>() ?? const {};
      return DesignSides(
        images: {
          for (final e in drawn.entries)
            if ('${e.value}'.isNotEmpty) e.key: '${e.value}',
        },
        failed: [for (final f in (j['failed'] as List? ?? const [])) '$f'],
      );
    } on ApiException catch (e) {
      if (e.status == 503) throw const AiUnavailable();
      throw AiFailure(e.message);
    }
  }
}
