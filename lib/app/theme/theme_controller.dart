import "dart:convert";

import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/app/theme/theme_settings.dart";

const _kPrefsKey = "themeSettings";

/// Persists and exposes [ThemeSettings] through Riverpod.
class ThemeController extends Notifier<ThemeSettings> {
  @override
  ThemeSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null) {
      return ThemeSettings.fromJson(raw);
    }
    return const ThemeSettings();
  }

  Future<void> update(ThemeSettings next) async {
    if (next == state) return;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kPrefsKey, json.encode(next.toJson()));
    state = next;
  }
}

final themeControllerProvider =
    NotifierProvider<ThemeController, ThemeSettings>(ThemeController.new);
