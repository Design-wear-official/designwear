import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../cms/cms_config.dart';

CmsConfig getCmsConfig() => CmsConfig(
  baseUrl: dotenv.env['SETHUCMS_INTERNAL_URL'] ?? '',
  connectionId: dotenv.env['SETHUCMS_INTERNAL_CONNECTION_ID'] ?? '',
  viewerToken: dotenv.env['SETHUCMS_INTERNAL_VIEWER_TOKEN'] ?? '',
);

/// Base URL of the DesignWear API (auth, orders, community, AI), or empty.
String getApiUrl() => dotenv.env['DESIGNWEAR_INTERNAL_API_URL'] ?? '';
