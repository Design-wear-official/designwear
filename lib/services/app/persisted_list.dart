import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../logging/app_log.dart';

/// A list of JSON-serialisable items persisted on this device.
class PersistedList<T> extends ChangeNotifier {
  PersistedList({
    required this.key,
    required this.fromJson,
    required this.toJson,
    required this.idOf,
  });

  final String key;
  final T Function(Map<String, Object?>) fromJson;
  final Map<String, Object?> Function(T) toJson;
  final String Function(T) idOf;

  final List<T> _items = [];
  List<T> get items => List.unmodifiable(_items);

  Future<void> load() async {
    try {
      final raw = (await SharedPreferences.getInstance()).getString(key);
      if (raw != null) {
        _items
          ..clear()
          ..addAll(
            (jsonDecode(raw) as List).map((e) => fromJson((e as Map).cast())),
          );
        notifyListeners();
      }
    } catch (e) {
      AppLog.instance.warning('storage', 'Could not load $key', e);
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(_items.map(toJson).toList()));
    } catch (e) {
      AppLog.instance.warning('storage', 'Could not save $key', e);
    }
  }

  /// Replaces the contents in memory (server-backed lists); nothing is saved.
  void setAll(List<T> items) {
    _items
      ..clear()
      ..addAll(items);
    notifyListeners();
  }

  Future<void> upsert(T item, {bool atFront = false}) async {
    final i = _items.indexWhere((e) => idOf(e) == idOf(item));
    if (i >= 0) {
      _items[i] = item;
    } else if (atFront) {
      _items.insert(0, item);
    } else {
      _items.add(item);
    }
    notifyListeners();
    await _save();
  }

  Future<void> remove(String id) async {
    _items.removeWhere((e) => idOf(e) == id);
    notifyListeners();
    await _save();
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    await _save();
  }
}
