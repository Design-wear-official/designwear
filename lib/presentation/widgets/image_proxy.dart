/// Product photos live on an image CDN (Sanity) that only allows browsers from
/// origins on its own list, so a web app on another origin gets "403 CORS
/// Origin not allowed". On web the DesignWear API fetches those photos instead
/// (and can resize them, which is lighter than the 1080x1440 originals).
///
/// Phones and desktop apps don't enforce CORS and load the CDN directly.
class ImageProxy {
  ImageProxy._();

  static String? _apiBase;

  /// Call once at startup with the API's base URL on web; null turns it off.
  static void configure(String? apiBase) =>
      _apiBase = apiBase?.replaceAll(RegExp(r'/+$'), '');

  static bool get enabled => _apiBase != null;

  static final _sanity = RegExp(
    r'^https://(cdn\.sanity\.io)/images/([a-z0-9]{4,20})/([a-z0-9-]{2,30})/([a-f0-9]{40}-\d{1,5}x\d{1,5}\.(?:jpg|jpeg|png|webp|gif))(?:\?.*)?$',
  );

  /// The URL to load [url] from: the API's image route for CDN photos when the
  /// proxy is on, otherwise [url] unchanged. [width] (logical px) asks for a
  /// smaller picture.
  static String resolve(String url, {int width = 800}) {
    final base = _apiBase;
    if (base == null) return url;
    final m = _sanity.firstMatch(url);
    if (m == null) return url;
    final w = width.clamp(16, 2000);
    return '$base/v1/img/${m[1]}/${m[2]}/${m[3]}/${m[4]}?w=$w&q=80&auto=format';
  }
}
