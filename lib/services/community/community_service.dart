import '../../api/api_client.dart';
import '../../models/challenge.dart';
import '../../models/design.dart';

/// Community designs on the DesignWear API.
class CommunityService {
  CommunityService(this.api);
  final ApiClient api;

  List<CommunityDesign> _parse(Map<String, Object?> j) => [
    for (final d in (j['designs'] as List))
      CommunityDesign.fromJson((d as Map).cast()),
  ];

  Future<List<CommunityDesign>> feed({bool popular = false}) async => _parse(
    await api.get(
      '/v1/designs',
      query: {'sort': popular ? 'popular' : 'recent'},
    ),
  );

  Future<List<CommunityDesign>> mine() async =>
      _parse(await api.get('/v1/designs', query: {'mine': '1'}));

  /// Designs other people shared with me by name.
  Future<List<CommunityDesign>> sharedWithMe() async =>
      _parse(await api.get('/v1/designs/shared-with-me'));

  /// One design; [token] is a private link's token.
  Future<CommunityDesign> get(String id, {String? token}) async {
    final design = CommunityDesign.fromJson(
      ((await api.get(
                '/v1/designs/${Uri.encodeComponent(id)}',
                query: {'token': ?token},
              ))['design']
              as Map)
          .cast(),
    );
    return token == null ? design : design.withAccessToken(token);
  }

  /// Who can open one of my designs.
  Future<DesignSharing> sharing(String id) async => DesignSharing.fromJson(
    await api.get('/v1/designs/${Uri.encodeComponent(id)}/sharing'),
  );

  /// Changes who can open one of my designs. Anything left out stays as it was.
  Future<DesignSharing> updateSharing(
    String id, {
    String? visibility,
    bool? link,
    bool regenerateLink = false,
    List<String> addEmails = const [],
    List<String> removeUserIds = const [],
    bool? allowRemix,
  }) async => DesignSharing.fromJson(
    await api.put('/v1/designs/${Uri.encodeComponent(id)}/sharing', {
      'visibility': ?visibility,
      'link': ?link,
      if (regenerateLink) 'regenerateLink': true,
      if (addEmails.isNotEmpty) 'addEmails': addEmails,
      if (removeUserIds.isNotEmpty) 'removeUserIds': removeUserIds,
      'allowRemix': ?allowRemix,
    }),
  );

  /// The open challenge with the latest start, or null when none is running.
  Future<Challenge?> currentChallenge() async {
    final c = (await api.get('/v1/challenges/current'))['challenge'];
    return c is Map ? Challenge.fromJson(c.cast()) : null;
  }

  /// A challenge and its entries, most liked first.
  Future<(Challenge, List<CommunityDesign>)> challengeEntries(String id) async {
    final j = await api.get(
      '/v1/challenges/${Uri.encodeComponent(id)}/entries',
    );
    return (Challenge.fromJson((j['challenge'] as Map).cast()), _parse(j));
  }

  /// Publishes (or updates) a Design Studio design. [previewImage] and
  /// [backPreviewImage] are base64 PNGs of the rendered garment.
  Future<CommunityDesign> publishStudio({
    required String name,
    required String garment,
    required Map<String, Object?> designJson,
    String? serverId,
    String? remixOfId,
    String? remixToken,
    String? challengeId,
    String? previewImage,
    String? backPreviewImage,
    bool publish = true,
  }) async {
    final j = await api.post('/v1/designs', {
      'id': ?serverId,
      if (serverId == null && remixOfId != null) 'remixOf': remixOfId,
      if (serverId == null && remixToken != null) 'remixToken': remixToken,
      if (serverId == null && challengeId != null) 'challengeId': challengeId,
      'name': name,
      'garment': garment,
      'designJson': designJson,
      'previewImage': ?previewImage,
      'backPreviewImage': ?backPreviewImage,
      'published': publish,
    });
    return CommunityDesign.fromJson((j['design'] as Map).cast());
  }

  /// Returns the new (liked, count) state.
  Future<(bool, int)> toggleLike(String id) async {
    final j = await api.post('/v1/designs/${Uri.encodeComponent(id)}/like');
    return (j['liked'] == true, (j['likeCount'] as num).toInt());
  }

  Future<void> delete(String id) async {
    await api.delete('/v1/designs/${Uri.encodeComponent(id)}');
  }
}
