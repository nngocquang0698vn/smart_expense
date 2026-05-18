import "dart:convert";

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "package:smart_expense/app/theme/theme_settings.dart";

const _kPrefsKey = "themeSettings";

/// Manages [ThemeSettings] persistence and notifies listeners on change.
///
/// Instantiate once during bootstrap and expose it through Riverpod.
class ThemeNotifier extends ChangeNotifier {
  ThemeNotifier(SharedPreferences prefs) : _prefs = prefs {
    _load();
  }

  final SharedPreferences _prefs;
  ThemeSettings _settings = const ThemeSettings();

  ThemeSettings get settings => _settings;

  void _load() {
    final raw = _prefs.getString(_kPrefsKey);
    if (raw != null) {
      _settings = ThemeSettings.fromJson(raw);
    }
  }

  Future<void> update(ThemeSettings next) async {
    if (next == _settings) return;
    _settings = next;
    await _prefs.setString(_kPrefsKey, json.encode(next.toJson()));
    notifyListeners();
  }
}
