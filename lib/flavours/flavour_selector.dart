// Centralized flavour-based selection for CMS config, app strings and
// the mode banner.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

import '../services/auth/firebase_env.dart';
import '../cms/cms_config.dart';
import 'external/cms_config.dart' as external_cms;
import 'internal/cms_config.dart' as internal_cms;
import 'external/app_strings.dart' as external_strings;
import 'internal/app_strings.dart' as internal_strings;

const String flavour = String.fromEnvironment(
  'FLAVOR',
  defaultValue: 'external',
);

bool get isInternal => flavour == 'internal';

T _pick<T>(T Function() external, T Function() internal) {
  switch (flavour) {
    case 'external':
      return external();
    case 'internal':
      return internal();
    default:
      throw UnsupportedError('Unknown flavour: $flavour');
  }
}

/// SethuCMS gateway settings for the current flavour, from `.env` /
/// `.env.local` (`SETHUCMS_*` for external, `SETHUCMS_INTERNAL_*` for internal).
CmsConfig getCmsConfig() =>
    _pick(external_cms.getCmsConfig, internal_cms.getCmsConfig);

/// Firebase options for this flavour (`FIREBASE_*` for external,
/// `FIREBASE_INTERNAL_*` for internal), or null when not configured.
FirebaseOptions? getFirebaseOptions() => _pick(
  () => FirebaseEnv.read('FIREBASE_'),
  () => FirebaseEnv.read('FIREBASE_INTERNAL_'),
);

String getApiUrl() => _pick(external_cms.getApiUrl, internal_cms.getApiUrl);

String getAppTitle() =>
    _pick(external_strings.getAppTitle, internal_strings.getAppTitle);

String getHomeTitle() =>
    _pick(external_strings.getHomeTitle, internal_strings.getHomeTitle);

String? getModeLabel() =>
    _pick(external_strings.getModeLabel, internal_strings.getModeLabel);
