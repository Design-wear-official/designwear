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

  Future<CommunityDesign> get(String id) async => CommunityDesign.fromJson(
    ((await api.get('/v1/designs/${Uri.encodeComponent(id)}'))['design'] as Map)
        .cast(),
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
    String? challengeId,
    String? previewImage,
    String? backPreviewImage,
    bool publish = true,
  }) async {
    final j = await api.post('/v1/designs', {
      'id': ?serverId,
      if (serverId == null && remixOfId != null) 'remixOf': remixOfId,
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
