import 'package:http/http.dart' as http;
import 'package:sethucms/sethucms.dart';

import 'cms_config.dart';

/// Thin wrapper over the SethuCMS client. The gateway holds the database
/// credentials, roles and rate limits; the app only ever sees records.
class CmsService {
  CmsService(this.config, {http.Client? httpClient})
    : _client = SethuClient(
        config.baseUrl,
        token: () => config.viewerToken,
        httpClient: httpClient,
      );

  final CmsConfig config;
  final SethuClient _client;

  /// Set once in `main()`; null when the CMS is not configured (e.g. `.env`
  /// not filled in yet), so callers can degrade instead of crashing.
  static CmsService? instance;

  Collection collection(String name) =>
      _client.collection(config.connectionId, name);

  Future<bool> isHealthy() => _client.isHealthy();

  void close() => _client.close();
}
