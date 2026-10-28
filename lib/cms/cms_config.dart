/// Where the SethuCMS gateway lives and which connection holds DesignWear's
/// content. The token must be a read-only (viewer) token: anything in the app
/// bundle can be extracted, so write tokens never belong here.
class CmsConfig {
  const CmsConfig({
    required this.baseUrl,
    required this.connectionId,
    required this.viewerToken,
  });

  final String baseUrl;
  final String connectionId;
  final String viewerToken;

  bool get isConfigured =>
      baseUrl.isNotEmpty && connectionId.isNotEmpty && viewerToken.isNotEmpty;
}
