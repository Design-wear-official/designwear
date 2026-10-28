import 'custom_design.dart';

/// A design as served by the community API. [designJson] is the Design Studio's
/// own format, so a remix opens with every element intact.
class CommunityDesign {
  const CommunityDesign({
    required this.id,
    required this.name,
    required this.garment,
    required this.creatorName,
    required this.creatorHandle,
    required this.likeCount,
    required this.remixCount,
    required this.liked,
    required this.mine,
    required this.price,
    this.published = false,
    this.designJson,
    this.previewImage,
    this.backPreviewImage,
    this.remixedFromName,
    this.lineage = const [],
  });

  final String id, name, garment, creatorName, creatorHandle;
  final int likeCount, remixCount;
  final bool liked, mine, published;
  final double price;
  final Map<String, Object?>? designJson;

  /// Base64 PNG of the front / back as rendered by the studio.
  final String? previewImage, backPreviewImage;
  final String? remixedFromName;
  final List<String> lineage; // creator handles, oldest first

  CommunityDesign withLike(bool liked, int count) => CommunityDesign(
    id: id,
    name: name,
    garment: garment,
    creatorName: creatorName,
    creatorHandle: creatorHandle,
    likeCount: count,
    remixCount: remixCount,
    liked: liked,
    mine: mine,
    price: price,
    published: published,
    designJson: designJson,
    previewImage: previewImage,
    backPreviewImage: backPreviewImage,
    remixedFromName: remixedFromName,
    lineage: lineage,
  );

  factory CommunityDesign.fromJson(Map<String, Object?> j) {
    final from = (j['remixedFrom'] as Map?)?.cast<String, Object?>();
    return CommunityDesign(
      id: '${j['id']}',
      name: '${j['name']}',
      garment: '${j['garment']}',
      creatorName: '${j['creatorName'] ?? ''}',
      creatorHandle: '${j['creatorHandle'] ?? ''}',
      likeCount: (j['likeCount'] as num?)?.toInt() ?? 0,
      remixCount: (j['remixCount'] as num?)?.toInt() ?? 0,
      liked: j['liked'] == true,
      mine: j['mine'] == true,
      published: j['published'] == true,
      price: (j['price'] as num?)?.toDouble() ?? 499,
      designJson: (j['designJson'] as Map?)?.cast<String, Object?>(),
      previewImage: j['previewImage'] as String?,
      backPreviewImage: j['backPreviewImage'] as String?,
      remixedFromName: from?['name'] as String?,
      lineage: [
        for (final l in (j['lineage'] as List? ?? const []))
          '${(l as Map)['handle']}',
      ],
    );
  }

  /// An editable copy for the studio, or null for a design with no studio data.
  CustomDesign? toStudioDesign() {
    final json = designJson;
    if (json == null) return null;
    return CustomDesign.fromJson(json.cast<String, dynamic>())
        .copyWith(name: '$name remix');
  }
}
