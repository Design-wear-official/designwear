/// AI features need a server that holds the model keys; the app never ships
/// one. There is exactly one chat bot: the Design Studio assistant
/// ([designAgent]), which edits the design from what the user asks. Virtual
/// try-on and graphic generation are not chats. Until [AiService.instance] is
/// replaced by [RemoteAiService] everything reports "not connected".
abstract class AiService {
  static AiService instance = const UnconfiguredAiService();

  bool get isConfigured;
  bool get agentEnabled => isConfigured;
  bool get tryOnEnabled => isConfigured;

  /// A photo of the person wearing the product, or their custom design when
  /// [garmentImage] is given instead of a catalog [productId].
  Future<List<int>> tryOn({
    required List<int> personPhoto,
    String? productId,
    List<int>? garmentImage,
    String? title,
  });

  /// Design Studio assistant: a reply and, when the model made one, a design
  /// (the studio's design JSON) to apply.
  Future<({String text, Map<String, Object?>? design})> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
  });

  /// A PNG graphic for [prompt], or throws.
  Future<List<int>> designImage(String prompt);

  /// Artwork for every face of the garment (front, back and both sleeves) for [prompt]: the front is
  /// drawn first and the others in its style. A face that could not be drawn is in [DesignSides.failed];
  /// throws only when nothing could be drawn. The customer's own [images] (pictures they attached) are
  /// references for every face.
  Future<DesignSides> designSides(
    String prompt, {
    List<List<int>> images = const [],
  }) async => throw const AiUnavailable();
}

class UnconfiguredAiService implements AiService {
  const UnconfiguredAiService();

  @override
  bool get isConfigured => false;

  @override
  bool get agentEnabled => false;

  @override
  bool get tryOnEnabled => false;

  @override
  Future<List<int>> tryOn({
    required List<int> personPhoto,
    String? productId,
    List<int>? garmentImage,
    String? title,
  }) async => throw const AiUnavailable();

  @override
  Future<({String text, Map<String, Object?>? design})> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
  }) async => throw const AiUnavailable();

  @override
  Future<List<int>> designImage(String prompt) async =>
      throw const AiUnavailable();
}

/// The pictures for each face of the garment, as base64 PNG, and the faces that could not be drawn.
class DesignSides {
  const DesignSides({required this.images, this.failed = const []});
  final Map<String, String>
  images; // 'front' | 'back' | 'left' | 'right' -> base64 PNG
  final List<String> failed;
}

/// The service is connected but this request failed (message is user-safe).
class AiFailure implements Exception {
  const AiFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

class AiUnavailable implements Exception {
  const AiUnavailable();
  @override
  String toString() => 'The AI service is not connected yet.';
}
