import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:designwear/config/config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:designwear/services/logging_service.dart';

class User {
  final String? id;
  final String? phone;
  final String? email;
  final String? name;
  final String? photoUrl;
  final List<Map<String, dynamic>> addresses;
  final List<Map<String, dynamic>> paymentMethods;
  final bool isGuest;

  User({
    this.id,
    this.phone,
    this.email,
    this.name,
    this.photoUrl,
    this.addresses = const [],
    this.paymentMethods = const [],
    this.isGuest = false,
  });

  bool get isLoggedIn => id != null;
}

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser?.isLoggedIn ?? false;
  bool get isLoading => _isLoading;

  String get _baseUrl => WebApiConfig.baseUrl;

  AuthService() {
    _loadUserFromStorage();
  }

  void init() {
    if (!kIsWeb && !Platform.isWindows && !Platform.isLinux) {
      _initFcm();
    }
  }

  Future<void> _initFcm() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    messaging.getToken().then((token) {
      if (token != null) _syncFcmToken(token);
    });
    messaging.onTokenRefresh.listen(_syncFcmToken);
  }

  Future<void> _syncFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('mem_fcm_token');
    await prefs.setString('mem_fcm_token', token);
    if (_currentUser?.id != null && storedToken != token) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/auth/update'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'uid': _currentUser!.id, 'fcmToken': token}),
        );
      } catch (e) {
        LoggingService.instance.logError('Failed to sync fcm token', error: e);
      }
    }
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final uid = prefs.getString('auth_uid');

    if (token != null && uid != null) {
      List<Map<String, dynamic>> loadedAddresses = [];
      List<Map<String, dynamic>> loadedPayments = [];
      try {
        final addrStr = prefs.getString('auth_addresses');
        if (addrStr != null) {
          loadedAddresses =
              List<Map<String, dynamic>>.from(jsonDecode(addrStr));
        }
        final payStr = prefs.getString('auth_payment_methods');
        if (payStr != null) {
          loadedPayments =
              List<Map<String, dynamic>>.from(jsonDecode(payStr));
        }
      } catch (e) {
        LoggingService.instance.logError('Error parsing stored lists', error: e);
      }

      _currentUser = User(
        id: uid,
        email: prefs.getString('auth_email'),
        name: prefs.getString('auth_name'),
        photoUrl: prefs.getString('auth_photo_url'),
        addresses: loadedAddresses,
        paymentMethods: loadedPayments,
        isGuest: prefs.getBool('auth_isGuest') ?? false,
      );
    } else {
      _currentUser = null;
    }
    notifyListeners();
  }

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    if (data['token'] != null) {
      await prefs.setString('auth_token', data['token']);
    }
    await prefs.setString('auth_uid', data['uid'] ?? '');
    if (data['email'] != null) await prefs.setString('auth_email', data['email']);
    if (data['name'] != null) await prefs.setString('auth_name', data['name']);
    if (data['photoUrl'] != null) {
      await prefs.setString('auth_photo_url', data['photoUrl']);
    }
    if (data['addresses'] != null) {
      await prefs.setString('auth_addresses', jsonEncode(data['addresses']));
    }
    if (data['paymentMethods'] != null) {
      await prefs.setString(
          'auth_payment_methods', jsonEncode(data['paymentMethods']));
    }
    if (data['isGuest'] != null) {
      await prefs.setBool('auth_isGuest', data['isGuest']);
    }
    await _loadUserFromStorage();
    final fcmToken = prefs.getString('mem_fcm_token');
    if (fcmToken != null) _syncFcmToken(fcmToken);
  }

  Future<void> _saveFirebaseUser(fb.User user, {bool isGuest = false}) async {
    final idToken = await user.getIdToken();
    await _saveSession({
      'uid': user.uid,
      'email': user.email,
      'name': user.displayName ?? user.email ?? 'Guest',
      'photoUrl': user.photoURL,
      'token': idToken,
      'isGuest': isGuest || user.isAnonymous,
    });
  }

  // ── Email / Password ──────────────────────────────────────────────────────

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await fb.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (cred.user == null) throw Exception('Sign-in returned no user');
      await _saveFirebaseUser(cred.user!);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_friendlyFirebaseError(e.code));
    } on SocketException {
      throw Exception(
          'No internet connection. Please check your WiFi or mobile data.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(
      String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await fb.FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user == null) throw Exception('Sign-up returned no user');
      await cred.user!.updateDisplayName(name);
      await cred.user!.reload();
      final refreshed = fb.FirebaseAuth.instance.currentUser;
      if (refreshed == null) throw Exception('User lost after reload');
      await _saveFirebaseUser(refreshed);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_friendlyFirebaseError(e.code));
    } on SocketException {
      throw Exception(
          'No internet connection. Please check your WiFi or mobile data.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Guest (anonymous) ─────────────────────────────────────────────────────

  Future<void> loginAsGuest() async {
    _isLoading = true;
    notifyListeners();
    try {
      final cred = await fb.FirebaseAuth.instance.signInAnonymously();
      if (cred.user == null) throw Exception('Anonymous sign-in returned no user');
      await _saveFirebaseUser(cred.user!, isGuest: true);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_friendlyFirebaseError(e.code));
    } on SocketException {
      throw Exception(
          'No internet connection. Please check your WiFi or mobile data.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Google ────────────────────────────────────────────────────────────────

  static bool get isGoogleSignInSupported =>
      kIsWeb || !(Platform.isWindows || Platform.isLinux);

  Future<void> signInWithGoogle() async {
    if (!isGoogleSignInSupported) {
      throw Exception(
        'Google Sign-In is not supported on Windows. Please use email & password.',
      );
    }
    _isLoading = true;
    notifyListeners();
    try {
      if (kIsWeb) {
        // On web, google_sign_in requires a clientId which we don't configure.
        // Use Firebase's built-in popup flow instead — no extra setup needed.
        final provider = fb.GoogleAuthProvider();
        final result =
            await fb.FirebaseAuth.instance.signInWithPopup(provider);
        if (result.user == null) {
          throw Exception('Google sign-in returned no user');
        }
        await _saveFirebaseUser(result.user!);
      } else {
        // Mobile / macOS: use google_sign_in package.
        // google-services.json injects default_web_client_id on Android at build time.
        final googleUser = await GoogleSignIn().signIn();
        if (googleUser == null) return;

        final googleAuth = await googleUser.authentication;
        final idToken = googleAuth.idToken;
        if (idToken == null) throw Exception('Google did not return an ID token');

        final credential = fb.GoogleAuthProvider.credential(
          idToken: idToken,
          accessToken: googleAuth.accessToken,
        );
        final cred =
            await fb.FirebaseAuth.instance.signInWithCredential(credential);
        if (cred.user == null) {
          throw Exception('Firebase sign-in returned no user');
        }
        await _saveFirebaseUser(cred.user!);
      }
    } on SocketException {
      throw Exception(
          'No internet connection. Please check your WiFi or mobile data.');
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('ApiException: 10') || msg.contains('DEVELOPER_ERROR')) {
        throw Exception(
          'Google Sign-In is not configured for this build. '
          'Add this app\'s SHA-1 fingerprint to Firebase Console → '
          'Project Settings → Your Apps → com.vishwamai.designwear.',
        );
      }
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<void> updateProfile({String? name, String? email}) async {
    if (_currentUser?.id == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final user = fb.FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not signed in');
      if (name != null) await user.updateDisplayName(name);
      if (email != null) await user.verifyBeforeUpdateEmail(email);
      await user.reload();
      await _saveFirebaseUser(fb.FirebaseAuth.instance.currentUser!);
    } on fb.FirebaseAuthException catch (e) {
      throw Exception(_friendlyFirebaseError(e.code));
    } on SocketException {
      throw Exception('No internet connection.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String path) async {
    if (_currentUser?.id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_photo_url', path);
    await _loadUserFromStorage();
    try {
      await fb.FirebaseAuth.instance.currentUser?.updatePhotoURL(path);
    } catch (e) {
      LoggingService.instance.logError('Error syncing profile image to Firebase', error: e);
    }
  }

  // ── Addresses & Payment Methods ───────────────────────────────────────────

  Future<void> addAddress(Map<String, dynamic> address) async {
    if (_currentUser?.id == null) return;
    final currentList =
        List<Map<String, dynamic>>.from(_currentUser!.addresses);
    if (address['isDefault'] == true) {
      for (var a in currentList) { a['isDefault'] = false; }
    } else if (currentList.isEmpty) {
      address['isDefault'] = true;
    }
    currentList.add(address);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_addresses', jsonEncode(currentList));
    await _loadUserFromStorage();
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'uid': _currentUser!.id, 'addresses': currentList}),
      );
    } catch (e) {
      LoggingService.instance.logError('Error syncing addresses', error: e);
    }
  }

  Future<void> addPaymentMethod(Map<String, dynamic> method) async {
    if (_currentUser?.id == null) return;
    final currentList =
        List<Map<String, dynamic>>.from(_currentUser!.paymentMethods);
    if (method['isDefault'] == true) {
      for (var p in currentList) { p['isDefault'] = false; }
    } else if (currentList.isEmpty) {
      method['isDefault'] = true;
    }
    currentList.add(method);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_payment_methods', jsonEncode(currentList));
    await _loadUserFromStorage();
    try {
      await http.post(
        Uri.parse('$_baseUrl/auth/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(
            {'uid': _currentUser!.id, 'paymentMethods': currentList}),
      );
    } catch (e) {
      LoggingService.instance.logError('Error syncing payment methods', error: e);
    }
  }

  // ── Logout ────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_uid');
    await prefs.remove('auth_email');
    await prefs.remove('auth_name');
    await prefs.remove('auth_photo_url');
    await prefs.remove('auth_addresses');
    await prefs.remove('auth_payment_methods');
    await prefs.remove('auth_isGuest');

    if (isGoogleSignInSupported) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    try {
      await fb.FirebaseAuth.instance.signOut();
    } catch (_) {}

    _currentUser = null;
    notifyListeners();
  }

  // ── Error helpers ─────────────────────────────────────────────────────────

  String _friendlyFirebaseError(String code) {
    switch (code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password. Please try again.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please wait a few minutes and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network.';
      default:
        return code;
    }
  }
}
