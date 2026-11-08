import 'layers.dart';

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

  /// The assistant can bring in what is trending (a daily web search on the server).
  bool get trendsEnabled => false;

  /// A photo of the person wearing the product, or their custom design when
  /// [garmentImage] is given instead of a catalog [productId].
  Future<List<int>> tryOn({
    required List<int> personPhoto,
    String? productId,
    List<int>? garmentImage,
    String? title,
  });

  /// Design Studio assistant: a reply and, when the model made one, a design
  /// (the studio's design JSON) to apply. With [trends] the server brings in
  /// what is trending (its daily web search) even if the message does not say so.
  Future<DesignAgentReply> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
    bool trends = false,
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

  /// One transparent layer per print area of [garment] (front, back and sleeves by default), plus the
  /// mock-up views and contact sheet made from them. Throws [LayersUnsupported] when the server has no
  /// such route yet, and [AiFailure] with a user-ready message when refused (e.g. a protected name).
  Future<LayerJob> designLayers(
    String prompt, {
    List<List<int>> images = const [],
    String? garment,
    String? color,
    String? name,
    String? size,
    List<String> sides = const ['front', 'back', 'left', 'right'],
  }) async => throw const AiUnavailable();

  /// The bytes of a picture at a signed link from a [LayerJob].
  Future<List<int>> fetchLayerImage(String url) async =>
      throw const AiUnavailable();
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
  bool get trendsEnabled => false;

  @override
  Future<DesignAgentReply> designAgent({
    required String message,
    required Map<String, Object?> design,
    required List<({bool fromUser, String text})> history,
    List<List<int>> images = const [],
    bool trends = false,
  }) async => throw const AiUnavailable();

  @override
  Future<List<int>> designImage(String prompt) async =>
      throw const AiUnavailable();

  @override
  Future<DesignSides> designSides(
    String prompt, {
    List<List<int>> images = const [],
  }) async => throw const AiUnavailable();

  @override
  Future<LayerJob> designLayers(
    String prompt, {
    List<List<int>> images = const [],
    String? garment,
    String? color,
    String? name,
    String? size,
    List<String> sides = const ['front', 'back', 'left', 'right'],
  }) async => throw const LayersUnsupported();

  @override
  Future<List<int>> fetchLayerImage(String url) async =>
      throw const AiUnavailable();
}

/// The pictures for each face of the garment, as base64 PNG, and the faces that could not be drawn.
class DesignSides {
  const DesignSides({required this.images, this.failed = const []});
  final Map<String, String>
  images; // 'front' | 'back' | 'left' | 'right' -> base64 PNG
  final List<String> failed;
}

/// What the assistant answered: text, and when the model made one, a design to apply.
class DesignAgentReply {
  const DesignAgentReply({
    required this.text,
    this.design,
    this.trends,
    this.art,
  });
  final String text;
  final Map<String, Object?>? design;

  /// A self-contained description of the artwork, written by the server from the whole conversation;
  /// null when the reply did not edit the design. The pictures for each face are drawn from this.
  final String? art;

  /// Set when the answer drew on the server's web search for trends.
  final TrendsInfo? trends;
}

/// Where trend ideas came from: the day of the search and the pages it used.
class TrendsInfo {
  const TrendsInfo({required this.asOf, this.sources = const []});
  final String asOf;
  final List<({String title, String url})> sources;
}

/// The service is connected but this request failed (message is user-safe).
class AiFailure implements Exception {
  const AiFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The server has no print-layers route (an older API): callers fall back to one picture per face.
class LayersUnsupported implements Exception {
  const LayersUnsupported();
}

class AiUnavailable implements Exception {
  const AiUnavailable();
  @override
  String toString() => 'The AI service is not connected yet.';
}
