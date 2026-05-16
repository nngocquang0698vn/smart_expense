import "dart:convert";

import "package:flutter/material.dart";
import "package:shared_preferences/shared_preferences.dart";

import "theme_settings.dart";

const _kPrefsKey = "themeSettings";

/// Manages [ThemeSettings] persistence and notifies listeners on change.
///
/// Instantiate once in [main] after [SharedPreferences.getInstance] resolves,
/// then expose it via [ThemeScope] so any widget can read or mutate settings.
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

/// Makes [ThemeNotifier] available to the widget tree without prop drilling.
///
/// Usage:
/// ```dart
/// // Read current settings (rebuilds on change):
/// final themeNotifier = ThemeScope.of(context);
///
/// // Update the seed color:
/// ThemeScope.of(context).update(
///   themeNotifier.settings.copyWith(seedColor: Colors.indigo),
/// );
/// ```
class ThemeScope extends InheritedNotifier<ThemeNotifier> {
  const ThemeScope({
    super.key,
    required ThemeNotifier super.notifier,
    required super.child,
  });

  static ThemeNotifier of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, "ThemeScope not found in widget tree");
    return scope!.notifier!;
  }
}
