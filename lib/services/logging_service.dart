import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_core/firebase_core.dart';

enum LogLevel { info, warn, error, crash }

class LogRow {
  final DateTime timestamp;
  final LogLevel level;
  final String platform;
  final String device;
  final String osVersion;
  final String appVersion;
  final String flavor;
  final String page;
  final String userId;
  final String message;
  final String stackTrace;

  const LogRow({
    required this.timestamp,
    required this.level,
    required this.platform,
    required this.device,
    required this.osVersion,
    required this.appVersion,
    required this.flavor,
    required this.page,
    required this.userId,
    required this.message,
    required this.stackTrace,
  });

  static const _csvHeader =
      'timestamp,level,platform,device,os_version,app_version,flavor,page,user_id,message,stack_trace';

  static String get csvHeader => _csvHeader;

  String _escape(String s) => '"${s.replaceAll('"', '""')}"';

  String toCsvRow() => [
        _escape(timestamp.toIso8601String()),
        _escape(level.name),
        _escape(platform),
        _escape(device),
        _escape(osVersion),
        _escape(appVersion),
        _escape(flavor),
        _escape(page),
        _escape(userId),
        _escape(message),
        _escape(stackTrace),
      ].join(',');

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'level': level.name,
        'platform': platform,
        'device': device,
        'os_version': osVersion,
        'app_version': appVersion,
        'flavor': flavor,
        'page': page,
        'user_id': userId,
        'message': message,
        'stack_trace': stackTrace,
      };
}

/// A NavigatorObserver that tracks the current route name and updates
/// [LoggingService.instance] automatically. Wire into MaterialApp via
/// [LoggingService.instance.routeObserver].
class _LoggingNavigatorObserver extends NavigatorObserver {
  void _update(Route<dynamic>? route) {
    final name = route?.settings.name ?? route.runtimeType.toString();
    LoggingService.instance._currentPage = name;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      _update(newRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _update(previousRoute);
}

class LoggingService with WidgetsBindingObserver {
  static final LoggingService instance = LoggingService._internal();
  LoggingService._internal();

  static const _prefsKey = 'logging_service_buffer';
  static const _maxBufferSize = 500;
  static const _backendUrl =
      'https://designwear-backend.vishwamai.com/api/logs';
  static const _flushInterval = Duration(seconds: 30);

  // Metadata
  String _platform = '';
  String _device = '';
  String _osVersion = '';
  String _appVersion = '1.0.0+1';
  String _flavor = 'external';
  String _currentPage = '/';

  Timer? _flushTimer;
  bool _initialized = false;

  /// Wire into `MaterialApp(navigatorObservers: [LoggingService.instance.routeObserver])`
  /// to automatically track page changes.
  final NavigatorObserver routeObserver = _LoggingNavigatorObserver();

  // ── Init ──────────────────────────────────────────────────────────────────

  /// Call once from [mainCommon] after Firebase is set up.
  ///
  /// [flavor] should be 'internal' or 'external'.
  /// [appVersion] should be your pubspec version string, e.g. '1.0.0+1'.
  Future<void> init({
    String flavor = 'external',
    String appVersion = '1.0.0+1',
  }) async {
    if (_initialized) return;
    _initialized = true;
    _flavor = flavor;
    _appVersion = appVersion;
    _collectPlatformMetadata();
    WidgetsBinding.instance.addObserver(this);
    _flushTimer = Timer.periodic(_flushInterval, (_) => _flushToBackend());
  }

  void _collectPlatformMetadata() {
    if (kIsWeb) {
      _platform = 'web';
      _device = 'browser';
      _osVersion = 'web';
      return;
    }
    if (Platform.isAndroid) {
      _platform = 'android';
    } else if (Platform.isIOS) {
      _platform = 'ios';
    } else if (Platform.isWindows) {
      _platform = 'windows';
    } else if (Platform.isLinux) {
      _platform = 'linux';
    } else if (Platform.isMacOS) {
      _platform = 'macos';
    } else {
      _platform = 'unknown';
    }
    // dart:io provides OS version without extra packages.
    _osVersion = Platform.operatingSystemVersion;
    // Hostname serves as a reasonable device identifier on desktop.
    _device = Platform.localHostname;
  }

  // ── WidgetsBindingObserver ────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _flushToBackend();
    }
  }

  // ── Public API ────────────────────────────────────────────────────────────

  Future<void> log(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
  }) async {
    final userId = await _getUserId();
    final row = LogRow(
      timestamp: DateTime.now().toUtc(),
      level: level,
      platform: _platform,
      device: _device,
      osVersion: _osVersion,
      appVersion: _appVersion,
      flavor: _flavor,
      page: _currentPage,
      userId: userId,
      message: message,
      stackTrace: stackTrace?.toString() ??
          (error != null ? error.toString() : ''),
    );

    if (kDebugMode) {
      // ignore: avoid_print
      print('[LOG ${row.level.name.toUpperCase()}] ${row.message}');
    }

    await _appendToBuffer(row);

    if (level == LogLevel.error || level == LogLevel.crash) {
      unawaited(_flushToBackend());
    }
  }

  Future<void> logInfo(String message) =>
      log(message, level: LogLevel.info);

  Future<void> logWarn(String message) =>
      log(message, level: LogLevel.warn);

  Future<void> logError(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(message, level: LogLevel.error, error: error, stackTrace: stackTrace);

  Future<void> logCrash(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(message, level: LogLevel.crash, error: error, stackTrace: stackTrace);

  // ── Auto-fix helpers ──────────────────────────────────────────────────────

  /// Re-initializes Firebase if it hasn't been initialized.
  /// Pass [DefaultFirebaseOptions.currentPlatform] as [options].
  Future<void> autoFixFirebase(FirebaseOptions options) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
        await logWarn('Auto-fix: Firebase re-initialized');
      }
    } catch (e, st) {
      await logError('Auto-fix: Firebase re-init failed', error: e, stackTrace: st);
    }
  }

  /// Refreshes the Firebase ID token (force-refresh).
  Future<String?> autoFixAuthToken() async {
    try {
      final token =
          await fb.FirebaseAuth.instance.currentUser?.getIdToken(true);
      if (token != null) {
        await logWarn('Auto-fix: auth token force-refreshed');
      }
      return token;
    } catch (e, st) {
      await logError('Auto-fix: auth token refresh failed',
          error: e, stackTrace: st);
      return null;
    }
  }

  /// Clears and reloads SharedPreferences when corruption is detected.
  Future<SharedPreferences> autoFixSharedPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await logWarn('Auto-fix: SharedPreferences cleared due to corruption');
      return prefs;
    } catch (e, st) {
      await logError('Auto-fix: SharedPreferences clear failed',
          error: e, stackTrace: st);
      return SharedPreferences.getInstance();
    }
  }

  // ── Buffer ────────────────────────────────────────────────────────────────

  Future<String> _getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('auth_uid') ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _appendToBuffer(LogRow row) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_prefsKey) ?? [];
      existing.add(row.toCsvRow());
      final trimmed = existing.length > _maxBufferSize
          ? existing.sublist(existing.length - _maxBufferSize)
          : existing;
      await prefs.setStringList(_prefsKey, trimmed);
    } catch (e) {
      if (kDebugMode) debugPrint('[LoggingService] buffer write error: $e');
    }
  }

  Future<List<String>> _drainBuffer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rows = List<String>.from(prefs.getStringList(_prefsKey) ?? []);
      if (rows.isNotEmpty) await prefs.remove(_prefsKey);
      return rows;
    } catch (e) {
      if (kDebugMode) debugPrint('[LoggingService] buffer drain error: $e');
      return [];
    }
  }

  // ── Backend flush ─────────────────────────────────────────────────────────

  Future<void> _flushToBackend() async {
    final rows = await _drainBuffer();
    if (rows.isEmpty) return;

    final csv = '${LogRow.csvHeader}\n${rows.join('\n')}';

    try {
      final response = await http
          .post(
            Uri.parse(_backendUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'csv': csv, 'rows': rows.length}),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        if (kDebugMode) {
          debugPrint(
              '[LoggingService] flush failed ${response.statusCode}: ${response.body}');
        }
        await _rebuffer(rows);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LoggingService] flush error: $e');
      await _rebuffer(rows);
    }
  }

  Future<void> _rebuffer(List<String> rows) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_prefsKey) ?? [];
      final combined = [...rows, ...existing];
      final trimmed = combined.length > _maxBufferSize
          ? combined.sublist(combined.length - _maxBufferSize)
          : combined;
      await prefs.setStringList(_prefsKey, trimmed);
    } catch (_) {}
  }

  void dispose() {
    _flushTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
