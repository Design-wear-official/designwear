import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Raised when Google sign-in fails for a reason the person should hear about.
class GoogleSignInFailure implements Exception {
  const GoogleSignInFailure(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Gets a Firebase ID token for a Google account. The API verifies it and
/// issues the app's own session, so the Firebase session isn't kept.
abstract class GoogleIdTokenSource {
  static GoogleIdTokenSource instance = const NoGoogleSignIn();

  bool get isAvailable;

  /// Opens Google's account picker. Returns null if the person backed out.
  Future<String?> idToken();
}

class NoGoogleSignIn implements GoogleIdTokenSource {
  const NoGoogleSignIn();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> idToken() async => null;
}

class FirebaseGoogleIdTokenSource implements GoogleIdTokenSource {
  const FirebaseGoogleIdTokenSource();

  static const _cancelled = {
    'popup-closed-by-user',
    'cancelled-popup-request',
    'web-context-canceled',
    'web-context-cancelled',
    'canceled',
    'cancelled',
    'user-cancelled',
  };

  @override
  bool get isAvailable => Firebase.apps.isNotEmpty;

  @override
  Future<String?> idToken() async {
    final auth = FirebaseAuth.instance;
    try {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      final credential = kIsWeb
          ? await auth.signInWithPopup(provider)
          : await auth.signInWithProvider(provider);
      final token = await credential.user?.getIdToken();
      return token;
    } on FirebaseAuthException catch (e) {
      if (_cancelled.contains(e.code)) return null;
      throw GoogleSignInFailure(switch (e.code) {
        'network-request-failed' =>
          "Couldn't reach Google. Check your connection.",
        'account-exists-with-different-credential' => 'An account already exists with this email. Sign in with your password instead.',
        'user-disabled' => 'This account has been disabled.',
        'operation-not-allowed' =>
          'Google sign-in is not enabled for this app yet.',
        _ => 'Google sign-in failed. Please try again.',
      });
    } finally {
      // The API session is the app's session; don't leave a second one behind.
      try {
        await auth.signOut();
      } catch (_) {}
    }
  }
}
