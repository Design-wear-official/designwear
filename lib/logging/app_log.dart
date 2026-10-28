import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';

enum LogLevel { debug, info, warning, error }

class LogEntry {
  const LogEntry({
    required this.at,
    required this.level,
    required this.tag,
    required this.message,
    this.stack,
  });

  final DateTime at;
  final LogLevel level;
  final String tag;
  final String message;
  final String? stack;

  Map<String, Object?> toJson() => {
    'at': at.toUtc().toIso8601String(),
    'level': level.name,
    'tag': tag,
    'message': message,
    if (stack != null) 'stack': stack,
  };

  factory LogEntry.fromJson(Map<String, Object?> j) => LogEntry(
    at: DateTime.tryParse('${j['at']}')?.toLocal() ?? DateTime.now(),
    level: LogLevel.values.firstWhere(
      (l) => l.name == j['level'],
      orElse: () => LogLevel.info,
    ),
    tag: '${j['tag'] ?? ''}',
    message: '${j['message'] ?? ''}',
    stack: j['stack'] as String?,
  );

  @override
  String toString() =>
      '${at.toIso8601String()} ${level.name.toUpperCase().padRight(7)} [$tag] $message'
      '${stack == null ? '' : '\n$stack'}';
}

/// Removes secrets before a message is stored or sent anywhere.
String redact(String text) => text
    .replaceAll(
      RegExp(r'Bearer\s+[A-Za-z0-9._~+/=-]+', caseSensitive: false),
      'Bearer [redacted]',
    )
    .replaceAll(
      RegExp(r'eyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]*'),
      '[jwt]',
    )
    .replaceAllMapped(
      RegExp(
        r'''("?(?:password|token|secret|code|authorization)"?\s*[:=]\s*)("[^"]*"|'[^']*'|[^\s,&}]+)''',
        caseSensitive: false,
      ),
      (m) => '${m[1]}[redacted]',
    )
    .replaceAll(RegExp(r'[\w.+-]+@[\w-]+\.[\w.-]+'), '[email]');

/// App-wide log. Everything is kept locally (memory + the last entries on
/// disk, viewable in Settings → Diagnostics). Warnings and errors are also
/// sent to the DesignWear API in batches, unless the user turns that off.
class AppLog extends ChangeNotifier {
  AppLog._() : _persist = persistInstance;

  /// Whether the shared [instance] saves its entries to disk. Tests turn this
  /// off (before first use) so API calls don't leave save timers behind.
  static bool persistInstance = true;

  static final AppLog instance = AppLog._();

  /// For tests: a fresh log not wired to global state.
  @visibleForTesting
  AppLog.forTest() : _persist = true;

  final bool _persist;

  static const _localKey = 'log.local.v1';
  static const _remoteKey = 'log.remote.v1';
  static const maxInMemory = 300;
  static const maxOnDisk = 150;
  static const _maxQueued = 100;

  final List<LogEntry> _entries = [];
  final List<LogEntry> _queue = [];
  List<LogEntry> get entries => List.unmodifiable(_entries);

  ApiClient? _api;
  String _flavour = '';
  bool _remoteEnabled = true;
  bool get remoteEnabled => _remoteEnabled;
  bool get remoteAvailable => _api != null;

  Timer? _saveTimer;
  Timer? _flushTimer;
  bool _sending = false;

  /// Minimum level that is sent off the device.
  LogLevel remoteMinLevel = LogLevel.warning;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _remoteEnabled = prefs.getBool(_remoteKey) ?? true;
      final raw = prefs.getString(_localKey);
      if (raw != null) {
        _entries.insertAll(
          0,
          (jsonDecode(raw) as List).map(
            (e) => LogEntry.fromJson((e as Map).cast()),
          ),
        );
      }
    } catch (_) {}
    notifyListeners();
  }

  void attach({ApiClient? api, required String flavour}) {
    _api = api;
    _flavour = flavour;
    notifyListeners();
  }

  Future<void> setRemoteEnabled(bool value) async {
    _remoteEnabled = value;
    if (!value) _queue.clear();
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setBool(_remoteKey, value);
    } catch (_) {}
  }

  void debug(String tag, String message) => _add(LogLevel.debug, tag, message);
  void info(String tag, String message) => _add(LogLevel.info, tag, message);
  void warning(
    String tag,
    String message, [
    Object? error,
    StackTrace? stack,
  ]) => _add(
    LogLevel.warning,
    tag,
    error == null ? message : '$message: $error',
    stack,
  );
  void error(String tag, String message, [Object? error, StackTrace? stack]) =>
      _add(
        LogLevel.error,
        tag,
        error == null ? message : '$message: $error',
        stack,
      );

  void _add(LogLevel level, String tag, String message, [StackTrace? stack]) {
    String cap(String text, int max) =>
        text.length > max ? text.substring(0, max) : text;
    final entry = LogEntry(
      at: DateTime.now(),
      level: level,
      tag: tag,
      message: cap(redact(message), 1000),
      stack: stack == null ? null : cap(redact(stack.toString()), 4000),
    );
    _entries.add(entry);
    if (_entries.length > maxInMemory) {
      _entries.removeRange(0, _entries.length - maxInMemory);
    }
    if (kDebugMode) debugPrint(entry.toString());
    notifyListeners();
    _scheduleSave();

    if (_remoteEnabled && _api != null && level.index >= remoteMinLevel.index) {
      _queue.add(entry);
      if (_queue.length > _maxQueued) _queue.removeAt(0);
      // Errors go out almost immediately; warnings ride along with the next batch.
      _flushTimer ??= Timer(
        level == LogLevel.error
            ? const Duration(seconds: 2)
            : const Duration(seconds: 20),
        flush,
      );
    }
  }

  void _scheduleSave() {
    if (!_persist) return;
    _saveTimer ??= Timer(const Duration(seconds: 2), () async {
      _saveTimer = null;
      try {
        final tail = _entries.length > maxOnDisk
            ? _entries.sublist(_entries.length - maxOnDisk)
            : _entries;
        await (await SharedPreferences.getInstance()).setString(
          _localKey,
          jsonEncode([for (final e in tail) e.toJson()]),
        );
      } catch (_) {}
    });
  }

  /// Sends queued entries. Network failures keep them for the next try;
  /// rejections (4xx) drop them. Never logs its own failures, so it can't loop.
  Future<void> flush() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    final api = _api;
    if (api == null || _sending || _queue.isEmpty || !_remoteEnabled) return;
    _sending = true;
    final batch = _queue.take(50).toList();
    try {
      await api.request(
        'POST',
        '/v1/logs',
        body: {
          'app': {
            'version': '1.0.0',
            'flavour': _flavour,
            'platform': defaultTargetPlatform.name,
          },
          'entries': [for (final e in batch) e.toJson()],
        },
      );
      _queue.removeRange(0, batch.length);
    } on ApiException catch (e) {
      if (e.status >= 400 && e.status < 500 && e.status != 429) {
        _queue.removeRange(0, batch.length);
      }
    } catch (_) {
    } finally {
      _sending = false;
      if (_queue.isNotEmpty) {
        _flushTimer ??= Timer(const Duration(seconds: 60), flush);
      }
    }
  }

  Future<void> clear() async {
    _entries.clear();
    _queue.clear();
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).remove(_localKey);
    } catch (_) {}
  }

  String export() => _entries.map((e) => e.toString()).join('\n');

  /// Routes Flutter framework errors and uncaught async errors into the log.
  static void installGlobalHandlers() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      previous?.call(details);
      instance.error(
        'flutter',
        details.exceptionAsString(),
        null,
        details.stack,
      );
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      instance.error('uncaught', '$error', null, stack);
      return true;
    };
  }
}
