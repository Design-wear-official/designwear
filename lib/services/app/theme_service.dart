import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.dark;
  ThemeMode get mode => _mode;

  Future<void> load() async {
    try {
      final s = (await SharedPreferences.getInstance()).getString('theme.mode');
      _mode = ThemeMode.values.firstWhere(
        (m) => m.name == s,
        orElse: () => ThemeMode.dark,
      );
      notifyListeners();
    } catch (_) {}
  }

  Future<void> set(ThemeMode mode) async {
    _mode = mode;
    notifyListeners();
    try {
      await (await SharedPreferences.getInstance()).setString(
        'theme.mode',
        mode.name,
      );
    } catch (_) {}
  }
}
