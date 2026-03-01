import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class User {
  final String? id;
  final String? phone;
  final String? email;
  final String? name;
  final bool isGuest;

  User({this.id, this.phone, this.email, this.name, this.isGuest = false});

  bool get isLoggedIn => id != null;
}

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser?.isLoggedIn ?? false;
  bool get isLoading => _isLoading;

  String get _baseUrl =>
      dotenv.env['WEB_API_BASE_URL'] ?? 'http://10.0.2.2:3001/api';

  AuthService() {
    _loadUserFromStorage();
  }

  void init() {
    // Handled in constructor
  }

  Future<void> _loadUserFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final uid = prefs.getString('auth_uid');

    if (token != null && uid != null) {
      _currentUser = User(
        id: uid,
        email: prefs.getString('auth_email'),
        name: prefs.getString('auth_name'),
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

    if (data['email'] != null)
      await prefs.setString('auth_email', data['email']);
    if (data['name'] != null) await prefs.setString('auth_name', data['name']);
    if (data['isGuest'] != null)
      await prefs.setBool('auth_isGuest', data['isGuest']);

    await _loadUserFromStorage();
  }

  Future<void> signInWithEmail(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        await _saveSession(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Login failed');
      }
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
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/guest'),
        headers: {'Content-Type': 'application/json'},
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success']) {
        await _saveSession(data['data']);
      } else {
        throw Exception(data['error'] ?? 'Guest login failed');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateProfile({String? name, String? email}) async {
    // To keep it simple, just update local storage for now
    // A full implementation would PATCH /api/users/profile
    final prefs = await SharedPreferences.getInstance();
    if (name != null) await prefs.setString('auth_name', name);
    if (email != null) await prefs.setString('auth_email', email);
    await _loadUserFromStorage();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('auth_uid');
    await prefs.remove('auth_email');
    await prefs.remove('auth_name');
    await prefs.remove('auth_isGuest');

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
