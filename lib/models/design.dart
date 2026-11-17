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
    this.visibility = 'private',
    this.allowRemix = false,
    this.accessToken,
    this.designJson,
    this.previewImage,
    this.backPreviewImage,
    this.remixedFromName,
    this.lineage = const [],
  });

  final String id, name, garment, creatorName, creatorHandle;
  final int likeCount, remixCount;
  final bool liked, mine, published;

  /// 'private' (only the owner), 'shared' (named people and/or a private link) or 'public' (the community).
  final String visibility;

  /// Whether people it is shared with (or the public) may make a copy or order it.
  final bool allowRemix;

  /// The private-link token this design was opened with, if any (kept to make a copy of it).
  final String? accessToken;
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
    visibility: visibility,
    allowRemix: allowRemix,
    accessToken: accessToken,
    designJson: designJson,
    previewImage: previewImage,
    backPreviewImage: backPreviewImage,
    remixedFromName: remixedFromName,
    lineage: lineage,
  );

  CommunityDesign withAccessToken(String? token) => CommunityDesign(
    id: id,
    name: name,
    garment: garment,
    creatorName: creatorName,
    creatorHandle: creatorHandle,
    likeCount: likeCount,
    remixCount: remixCount,
    liked: liked,
    mine: mine,
    price: price,
    published: published,
    visibility: visibility,
    allowRemix: allowRemix,
    accessToken: token,
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
      visibility:
          '${j['visibility'] ?? (j['published'] == true ? 'public' : 'private')}',
      allowRemix: j['allowRemix'] == true,
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

/// Who a design is open to, as the owner sees it.
class DesignSharing {
  const DesignSharing({
    required this.visibility,
    required this.allowRemix,
    required this.linkToken,
    required this.people,
    this.notFound = const [],
  });

  final String visibility;
  final bool allowRemix;

  /// The private link's token, or null while the link is off.
  final String? linkToken;
  final List<({String userId, String name})> people;

  /// Emails that were not added because no DesignWear account uses them.
  final List<String> notFound;

  bool get linkOn => linkToken != null;

  factory DesignSharing.fromJson(Map<String, Object?> j) {
    final link = (j['link'] as Map?)?.cast<String, Object?>();
    return DesignSharing(
      visibility: '${j['visibility'] ?? 'private'}',
      allowRemix: j['allowRemix'] == true,
      linkToken: link?['enabled'] == true ? link!['token'] as String? : null,
      people: [
        for (final p in (j['people'] as List? ?? const []))
          (userId: '${(p as Map)['userId']}', name: '${p['name'] ?? ''}'),
      ],
      notFound: [for (final e in (j['notFound'] as List? ?? const [])) '$e'],
    );
  }
}

/// A link's `share` value as text: the design id, and for a private design a dot and the token.
String shareCode(String designId, [String? token]) =>
    token == null ? designId : '$designId.$token';

/// The design id and token (null for a public design) from a pasted code, or null when it is not one.
({String id, String? token})? parseShareCode(String input) {
  final m = RegExp(r'^(d_[A-Za-z0-9_-]+?)(?:\.([A-Za-z0-9_-]{16,}))?$')
      .firstMatch(Uri.decodeComponent(input.trim()));
  return m == null ? null : (id: m.group(1)!, token: m.group(2));
}
