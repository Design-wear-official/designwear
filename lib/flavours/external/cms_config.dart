import 'package:flutter_dotenv/flutter_dotenv.dart';

import '../../cms/cms_config.dart';

CmsConfig getCmsConfig() => CmsConfig(
  baseUrl: dotenv.env['SETHUCMS_URL'] ?? '',
  connectionId: dotenv.env['SETHUCMS_CONNECTION_ID'] ?? '',
  viewerToken: dotenv.env['SETHUCMS_VIEWER_TOKEN'] ?? '',
);

/// Base URL of the DesignWear API (auth, orders, community, AI), or empty.
String getApiUrl() => dotenv.env['DESIGNWEAR_API_URL'] ?? '';
