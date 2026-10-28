import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../api/api_client.dart';
import 'google_id_token_source.dart';
import '../../models/commerce.dart';
import '../../logging/app_log.dart';

/// Accounts. With an [ApiClient] they live on the DesignWear API (hashed
/// server-side, session token on the device). Without one they fall back to
/// this device only; passwords are then salted and hashed, but anyone with the
/// device storage can still reset them.
class AuthService extends ChangeNotifier {
  // ignore: prefer_initializing_formals (the public name is `google`)
  AuthService({this.api, GoogleIdTokenSource? google}) : _google = google {
    api?.onSessionExpired = () {
      _user = null;
      notifyListeners();
    };
  }

  final ApiClient? api;
  final GoogleIdTokenSource? _google;
  bool get isRemote => api != null;

  GoogleIdTokenSource get _googleSource =>
      _google ?? GoogleIdTokenSource.instance;

  /// Google sign-in needs the API (it issues the session) and a configured
  /// Firebase project on this platform.
  bool get googleAvailable => api != null && _googleSource.isAvailable;

  /// Signs in with Google. Returns an error message, or null on success *or* if
  /// the person closed the Google window (check [isSignedIn] to tell).
  Future<String?> signInWithGoogle() async {
    if (!googleAvailable) return 'Google sign-in is not set up yet.';
    try {
      final idToken = await _googleSource.idToken();
      if (idToken == null) return null;
      return await _remote(
        (a) => a.post('/v1/auth/google', {'idToken': idToken}),
      );
    } on GoogleSignInFailure catch (e) {
      return e.message;
    } catch (e) {
      AppLog.instance.warning('auth', 'Google sign-in failed', e);
      return 'Google sign-in failed. Please try again.';
    }
  }

  static const _usersKey = 'auth.users.v1';
  static const _sessionKey = 'auth.session.v1';

  final Map<String, Map<String, Object?>> _users = {};
  UserProfile? _user;
  UserProfile? get user => _user;
  bool get isSignedIn => _user != null;

  Future<void> load() async {
    final api = this.api;
    if (api != null) {
      await api.loadToken();
      if (api.hasToken) {
        try {
          final me = await api.get('/v1/me');
          _user = UserProfile.fromJson((me['user'] as Map).cast());
        } on ApiException catch (e) {
          // Only drop the session when the server rejects it; a network error
          // shouldn't sign anyone out.
          if (e.isUnauthenticated) await api.setToken(null);
        }
      }
      notifyListeners();
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_usersKey);
      if (raw != null) {
        (jsonDecode(raw) as Map).forEach((k, v) {
          _users['$k'] = (v as Map).cast<String, Object?>();
        });
      }
      final session = prefs.getString(_sessionKey);
      if (session != null && _users.containsKey(session)) {
        _user = UserProfile.fromJson(
          (_users[session]!['profile'] as Map).cast(),
        );
      }
      notifyListeners();
    } catch (e) {
      AppLog.instance.warning('auth', 'Could not load auth', e);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usersKey, jsonEncode(_users));
    final u = _user;
    if (u == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, u.email);
    }
  }

  static String _hash(String password, String salt) {
    List<int> digest = utf8.encode('$salt:$password');
    for (var i = 0; i < 10000; i++) {
      digest = sha256.convert(digest).bytes;
    }
    return base64Encode(digest);
  }

  static String _salt() {
    final r = Random.secure();
    return base64Encode(List.generate(16, (_) => r.nextInt(256)));
  }

  static String _norm(String email) => email.trim().toLowerCase();

  /// Returns an error message, or null on success.
  Future<String?> _remote(
    Future<Map<String, Object?>> Function(ApiClient api) call,
  ) async {
    try {
      final j = await call(api!);
      final token = j['token'];
      if (token is String) await api!.setToken(token);
      final user = j['user'];
      if (user is Map) _user = UserProfile.fromJson(user.cast());
      notifyListeners();
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    if (api != null) {
      return _remote(
        (a) => a.post('/v1/auth/register', {
          'name': name,
          'email': email,
          'password': password,
        }),
      );
    }
    final key = _norm(email);
    if (!key.contains('@') || key.length < 5) return 'Enter a valid email.';
    if (password.length < 8) return 'Password must be at least 8 characters.';
    if (name.trim().isEmpty) return 'Enter your name.';
    if (_users.containsKey(key)) {
      return 'An account with this email already exists.';
    }
    final salt = _salt();
    final profile = UserProfile(name: name.trim(), email: key);
    _users[key] = {
      'salt': salt,
      'hash': _hash(password, salt),
      'profile': profile.toJson(),
    };
    _user = profile;
    await _persist();
    notifyListeners();
    return null;
  }

  Future<String?> signIn(String email, String password) async {
    if (api != null) {
      return _remote(
        (a) => a.post('/v1/auth/login', {'email': email, 'password': password}),
      );
    }
    final record = _users[_norm(email)];
    if (record == null ||
        _hash(password, '${record['salt']}') != record['hash']) {
      return 'Incorrect email or password.';
    }
    _user = UserProfile.fromJson((record['profile'] as Map).cast());
    await _persist();
    notifyListeners();
    return null;
  }

  /// Server mode, step 1: emails a 6-digit code (always reports success, so it
  /// can't be used to discover which emails have accounts).
  Future<String?> requestPasswordReset(String email) async {
    try {
      await api!.post('/v1/auth/password-reset/request', {'email': email});
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// Server mode, step 2: sets the new password and signs out every session.
  Future<String?> confirmPasswordReset(
    String email,
    String code,
    String password,
  ) async {
    try {
      await api!.post('/v1/auth/password-reset/confirm', {
        'email': email,
        'code': code,
        'password': password,
      });
      return null;
    } on ApiException catch (e) {
      return e.message;
    }
  }

  /// On-device mode only.
  Future<String?> resetPassword(String email, String newPassword) async {
    final key = _norm(email);
    final record = _users[key];
    if (record == null) return 'No account on this device uses that email.';
    if (newPassword.length < 8) {
      return 'Password must be at least 8 characters.';
    }
    final salt = _salt();
    record['salt'] = salt;
    record['hash'] = _hash(newPassword, salt);
    await _persist();
    return null;
  }

  Future<void> updateProfile({String? name, String? phone}) async {
    final u = _user;
    if (u == null) return;
    if (api != null) {
      try {
        final j = await api!.patch('/v1/me', {'name': ?name, 'phone': ?phone});
        _user = UserProfile.fromJson((j['user'] as Map).cast());
        notifyListeners();
      } on ApiException catch (e) {
        AppLog.instance.warning('auth', 'Profile update failed: ${e.message}');
      }
      return;
    }
    _user = u.copyWith(name: name, phone: phone);
    _users[u.email]?['profile'] = _user!.toJson();
    await _persist();
    notifyListeners();
  }

  Future<void> signOut() async {
    _user = null;
    if (api != null) {
      await api!.setToken(null);
      notifyListeners();
      return;
    }
    await _persist();
    notifyListeners();
  }
}
