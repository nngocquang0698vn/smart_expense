import "dart:convert";

import "package:flutter/material.dart";

import "constants.dart";

/// Brightness mode chosen by the user (persisted).
enum AppThemePreference {
  /// Follow [MediaQuery.platformBrightness].
  system,

  /// Always [ThemeData] light variant.
  light,

  /// Always [ThemeData] dark variant.
  dark;

  static AppThemePreference fromJson(Object? raw) {
    if (raw is! String) return AppThemePreference.system;
    return switch (raw) {
      "light" => AppThemePreference.light,
      "dark" => AppThemePreference.dark,
      _ => AppThemePreference.system,
    };
  }

  String get jsonValue => name;

  ThemeMode get materialThemeMode => switch (this) {
        AppThemePreference.system => ThemeMode.system,
        AppThemePreference.light => ThemeMode.light,
        AppThemePreference.dark => ThemeMode.dark,
      };
}

/// Immutable snapshot of the user's theme preferences.
///
/// Used as the single input to [AppTheme.build]. Keeping this separate from
/// [ThemeNotifier] means [AppTheme] stays a pure function and is easily
/// testable without SharedPreferences.
///
/// **Persisted keys:**
/// - `seedColor`          — ARGB int of the accent seed colour.
/// - `useColoredSurfaces` — whether scaffold backgrounds get a soft
///   tint derived from the seed colour (light: pastel; dark: subtle glow).
/// - `themePreference`    — `"system"` | `"light"` | `"dark"`.
class ThemeSettings {
  const ThemeSettings({
    this.seedColor = AppColors.brand,
    this.useColoredSurfaces = true,
    this.themePreference = AppThemePreference.system,
  });

  final Color seedColor;

  /// When `true`, scaffold backgrounds receive a very-light tint of
  /// [seedColor] (light) or a subtle blend on dark grey (dark).
  /// When `false`, neutral backgrounds are used instead.
  final bool useColoredSurfaces;

  /// Which theme [MaterialApp] applies ([ThemeMode]).
  final AppThemePreference themePreference;

  ThemeSettings copyWith({
    Color? seedColor,
    bool? useColoredSurfaces,
    AppThemePreference? themePreference,
  }) {
    return ThemeSettings(
      seedColor: seedColor ?? this.seedColor,
      useColoredSurfaces: useColoredSurfaces ?? this.useColoredSurfaces,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  Map<String, dynamic> toJson() => {
        "seedColor": seedColor.toARGB32(),
        "useColoredSurfaces": useColoredSurfaces,
        "themePreference": themePreference.jsonValue,
      };

  factory ThemeSettings.fromJson(String raw) {
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      return ThemeSettings(
        seedColor: Color(m["seedColor"] as int? ?? AppColors.brand.toARGB32()),
        useColoredSurfaces: m["useColoredSurfaces"] as bool? ?? true,
        themePreference: AppThemePreference.fromJson(m["themePreference"]),
      );
    } catch (_) {
      return const ThemeSettings();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeSettings &&
      other.seedColor == seedColor &&
      other.useColoredSurfaces == useColoredSurfaces &&
      other.themePreference == themePreference;

  @override
  int get hashCode =>
      Object.hash(seedColor, useColoredSurfaces, themePreference);
}
