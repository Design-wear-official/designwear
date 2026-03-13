import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

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
    if (!kIsWeb) {
      _initFcm();
    }
  }

  Future<void> _initFcm() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    messaging.getToken().then((token) {
      if (token != null) _syncFcmToken(token);
    });

    messaging.onTokenRefresh.listen((token) {
      _syncFcmToken(token);
    });
  }

  Future<void> _syncFcmToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('mem_fcm_token');
    
    // Always store token locally
    await prefs.setString('mem_fcm_token', token);

    // If logged in, and token is new or hasn't been synced this session
    if (_currentUser?.id != null && storedToken != token) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/auth/update'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'uid': _currentUser!.id,
            'fcmToken': token,
          }),
        );
      } catch (e) {
        debugPrint('Failed to sync fcm token: $e');
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
          loadedAddresses = List<Map<String, dynamic>>.from(jsonDecode(addrStr));
        }
        final payStr = prefs.getString('auth_payment_methods');
        if (payStr != null) {
          loadedPayments = List<Map<String, dynamic>>.from(jsonDecode(payStr));
        }
      } catch (e) {
        debugPrint('Error parsing stored lists: $e');
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

    if (data['email'] != null) {
      await prefs.setString('auth_email', data['email']);
    }
    if (data['name'] != null) {
      await prefs.setString('auth_name', data['name']);
    }
    if (data['photoUrl'] != null) {
      await prefs.setString('auth_photo_url', data['photoUrl']);
    }
    if (data['addresses'] != null) {
      await prefs.setString('auth_addresses', jsonEncode(data['addresses']));
    }
    if (data['paymentMethods'] != null) {
      await prefs.setString('auth_payment_methods', jsonEncode(data['paymentMethods']));
    }
    if (data['isGuest'] != null) {
      await prefs.setBool('auth_isGuest', data['isGuest']);
    }

    await _loadUserFromStorage();

    // After login, guarantee latest loaded FCM token is synced to this user.
    final token = prefs.getString('mem_fcm_token');
    if (token != null) {
      _syncFcmToken(token); // safe duplicate call handles it
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        // For seamless integration with backend lists if they aren't explicitly returned down the line,
        // it may be helpful to ensure that `_saveSession` acts as a full merge if missing.
        // Usually, the backend returns the full user document from login.
        await _saveSession(data['data']);
      } else {
        final msg = data['error'] ?? 'Login failed';
        throw Exception(_friendlyError(msg));
      }
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your WiFi or mobile data.',
      );
    } on http.ClientException {
      throw Exception('Could not reach the server. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signUpWithEmail(
    String email,
    String password,
    String name,
  ) async {
    _isLoading = true;
    notifyListeners();
    try {
      // 1. Register User
      final regResponse = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password, 'name': name}),
      );

      final regData = jsonDecode(regResponse.body);
      if (regResponse.statusCode != 200 || !regData['success']) {
        throw Exception(regData['error'] ?? 'Registration failed');
      }

      // 2. Immediately Login to get Token
      await signInWithEmail(email, password);
    } finally {
      if (_isLoading) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loginAsGuest() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/guest'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        await _saveSession(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Guest login failed');
      }
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your WiFi or mobile data.',
      );
    } on http.ClientException {
      throw Exception('Could not reach the server. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();
    try {
      // serverClientId = the Web OAuth Client ID from google-services.json (type 3)
      const serverClientId =
          '350351347585-0pnnds7cvia2salbb6nqj2a3p6mq372q.apps.googleusercontent.com';
      final GoogleSignIn googleSignIn = GoogleSignIn(
        serverClientId: serverClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // User cancelled

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) throw Exception('Failed to get Google ID token');

      // Try backend first; fall back to local session if unreachable.
      try {
        final response = await http
            .post(
              Uri.parse('$_baseUrl/auth/google'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'idToken': idToken}),
            )
            .timeout(const Duration(seconds: 12));

        final data = jsonDecode(response.body);
        if (response.statusCode == 200 && data['success']) {
          await _saveSession(data['data']);
          return;
        }
        debugPrint('Google auth backend error: ${data['error']}');
      } catch (networkErr) {
        // Backend unreachable — fall through to local session
        debugPrint('Backend unreachable for Google auth: $networkErr');
      }

      // Local session fallback: sign in from Google account directly
      await _saveSession({
        'uid': googleUser.id,
        'email': googleUser.email,
        'name': googleUser.displayName ?? googleUser.email,
        'token': idToken,
        'isGuest': false,
      });
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your WiFi or mobile data.',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Converts raw Firebase/server error codes to human-readable messages.
  String _friendlyError(String raw) {
    if (raw.contains('INVALID_LOGIN_CREDENTIALS') ||
        raw.contains('INVALID_PASSWORD')) {
      return 'Incorrect email or password. Please try again.';
    }
    if (raw.contains('EMAIL_NOT_FOUND') || raw.contains('USER_NOT_FOUND')) {
      return 'No account found with this email.';
    }
    if (raw.contains('TOO_MANY_ATTEMPTS') ||
        raw.contains('TOO_MANY_REQUESTS')) {
      return 'Too many failed attempts. Please wait a few minutes and try again.';
    }
    if (raw.contains('USER_DISABLED')) {
      return 'This account has been disabled. Please contact support.';
    }
    return raw;
  }

  Future<void> updateProfile({String? name, String? email}) async {
    if (_currentUser?.id == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/update'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'uid': _currentUser!.id,
              // ignore: use_null_aware_elements
              if (name != null) 'name': name,
              // ignore: use_null_aware_elements
              if (email != null) 'email': email,
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        final prefs = await SharedPreferences.getInstance();
        if (name != null) await prefs.setString('auth_name', name);
        if (email != null) await prefs.setString('auth_email', email);
        await _loadUserFromStorage();
      } else {
        throw Exception(data['error'] ?? 'Profile update failed');
      }
    } on SocketException {
      throw Exception('No internet connection.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String path) async {
    if (_currentUser?.id == null) return;
    
    // Optimistically update local storage so UI reflects immediately
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_photo_url', path);
    await _loadUserFromStorage();

    try {
      // Background sync to backend
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': _currentUser!.id,
          'photoUrl': path,
        }),
      );
      
      if (response.statusCode != 200) {
         debugPrint('Failed to sync profile image to backend: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error syncing profile image to backend: $e');
    }
  }

  Future<void> addAddress(Map<String, dynamic> address) async {
    if (_currentUser?.id == null) return;
    
    final currentList = List<Map<String, dynamic>>.from(_currentUser!.addresses);
    
    // If setting as default, make all others non-default
    if (address['isDefault'] == true) {
      for (var a in currentList) {
        a['isDefault'] = false;
      }
    } else if (currentList.isEmpty) {
      address['isDefault'] = true; // First one is default
    }

    currentList.add(address);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_addresses', jsonEncode(currentList));
    await _loadUserFromStorage();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': _currentUser!.id,
          'addresses': currentList,
        }),
      );
      if (response.statusCode != 200) debugPrint('Failed to sync addresses: ${response.body}');
    } catch (e) {
      debugPrint('Error syncing addresses: $e');
    }
  }

  Future<void> addPaymentMethod(Map<String, dynamic> method) async {
    if (_currentUser?.id == null) return;
    
    final currentList = List<Map<String, dynamic>>.from(_currentUser!.paymentMethods);
    if (method['isDefault'] == true) {
      for (var p in currentList) {
        p['isDefault'] = false;
      }
    } else if (currentList.isEmpty) {
      method['isDefault'] = true;
    }

    currentList.add(method);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_payment_methods', jsonEncode(currentList));
    await _loadUserFromStorage();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'uid': _currentUser!.id,
          'paymentMethods': currentList,
        }),
      );
      if (response.statusCode != 200) debugPrint('Failed to sync payment methods: ${response.body}');
    } catch (e) {
      debugPrint('Error syncing payment methods: $e');
    }
  }

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

    try {
      await GoogleSignIn().signOut();
    } catch (e) {
      // Ignore error if not signed in with Google
    }

    _currentUser = null;
    notifyListeners();
  }

  // ---- Phone Auth (Removed during backend migration) ----
  Future<void> sendOtp(String phoneNumber) async {
    throw UnimplementedError(
      'Phone authentication is disabled in this version. Please use Email/Password.',
    );
  }

  Future<void> loginWithPhone(String otp) async {
    throw UnimplementedError(
      'Phone authentication is disabled in this version. Please use Email/Password.',
    );
  }
}
