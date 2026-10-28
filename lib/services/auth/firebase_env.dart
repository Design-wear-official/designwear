import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Firebase options for the current platform, read from `.env` so no project
/// config is committed. Returns null when Firebase isn't configured (or the
/// platform has no Firebase Auth support), and the app simply hides Google
/// sign-in.
///
/// With prefix `FIREBASE_` the keys are FIREBASE_PROJECT_ID,
/// FIREBASE_MESSAGING_SENDER_ID, FIREBASE_AUTH_DOMAIN (web), FIREBASE_STORAGE_BUCKET
/// (optional) and, per platform, FIREBASE_{WEB,ANDROID,IOS,MACOS}_API_KEY and
/// _APP_ID, plus FIREBASE_IOS_BUNDLE_ID / FIREBASE_MACOS_BUNDLE_ID.
class FirebaseEnv {
  FirebaseEnv._();

  /// Firebase Auth runs on web, Android, iOS and macOS only.
  static bool get platformSupported {
    if (kIsWeb) return true;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android ||
      TargetPlatform.iOS ||
      TargetPlatform.macOS => true,
      _ => false,
    };
  }

  static FirebaseOptions? read(String prefix, {Map<String, String>? env}) {
    if (!platformSupported) return null;
    final e = env ?? dotenv.env;
    String? get(String key) {
      final v = e['$prefix$key'];
      return (v == null || v.trim().isEmpty) ? null : v.trim();
    }

    final platform = kIsWeb
        ? 'WEB'
        : switch (defaultTargetPlatform) {
            TargetPlatform.android => 'ANDROID',
            TargetPlatform.iOS => 'IOS',
            _ => 'MACOS',
          };
    final projectId = get('PROJECT_ID');
    final apiKey = get('${platform}_API_KEY');
    final appId = get('${platform}_APP_ID');
    final sender = get('MESSAGING_SENDER_ID');
    if (projectId == null ||
        apiKey == null ||
        appId == null ||
        sender == null) {
      return null;
    }
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: sender,
      projectId: projectId,
      authDomain: kIsWeb
          ? (get('AUTH_DOMAIN') ?? '$projectId.firebaseapp.com')
          : null,
      storageBucket: get('STORAGE_BUCKET'),
      iosBundleId: get('${platform}_BUNDLE_ID'),
    );
  }
}
