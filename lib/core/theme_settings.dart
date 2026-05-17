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
    if (raw is! String) return AppThemePreference.light;
    return switch (raw) {
      "dark" => AppThemePreference.dark,
      "system" => AppThemePreference.system,
      _ => AppThemePreference.light,
    };
  }

  String get jsonValue => name;

  ThemeMode get materialThemeMode => switch (this) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  bool get isDark => this == AppThemePreference.dark;
}

/// Immutable snapshot of the user's theme preferences.
class ThemeSettings {
  const ThemeSettings({
    this.seedColor = AppColors.brand,
    this.useColoredSurfaces = true,
    this.enableAccentColors = false,
    this.themePreference = AppThemePreference.light,
  });

  final Color seedColor;

  /// Soft scaffold tint from [effectiveSeedColor].
  final bool useColoredSurfaces;

  /// When `false`, only default brand green is used (no preset picker).
  final bool enableAccentColors;

  final AppThemePreference themePreference;

  /// Accent applied to [ColorScheme] and chrome — always brand when
  /// [enableAccentColors] is off.
  Color get effectiveSeedColor =>
      enableAccentColors ? seedColor : AppColors.brand;

  /// Surfaces follow the seed tint when coloured backgrounds are on.
  bool get effectiveColoredSurfaces => useColoredSurfaces;

  ThemeSettings copyWith({
    Color? seedColor,
    bool? useColoredSurfaces,
    bool? enableAccentColors,
    AppThemePreference? themePreference,
  }) {
    return ThemeSettings(
      seedColor: seedColor ?? this.seedColor,
      useColoredSurfaces: useColoredSurfaces ?? this.useColoredSurfaces,
      enableAccentColors: enableAccentColors ?? this.enableAccentColors,
      themePreference: themePreference ?? this.themePreference,
    );
  }

  Map<String, dynamic> toJson() => {
    "seedColor": seedColor.toARGB32(),
    "useColoredSurfaces": useColoredSurfaces,
    "enableAccentColors": enableAccentColors,
    "themePreference": themePreference.jsonValue,
  };

  factory ThemeSettings.fromJson(String raw) {
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      final storedSeed = Color(
        m["seedColor"] as int? ?? AppColors.brand.toARGB32(),
      );
      final hadCustomSeed = storedSeed != AppColors.brand;
      return ThemeSettings(
        seedColor: storedSeed,
        useColoredSurfaces: m["useColoredSurfaces"] as bool? ?? true,
        enableAccentColors: m["enableAccentColors"] as bool? ?? hadCustomSeed,
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
      other.enableAccentColors == enableAccentColors &&
      other.themePreference == themePreference;

  @override
  int get hashCode => Object.hash(
    seedColor,
    useColoredSurfaces,
    enableAccentColors,
    themePreference,
  );
}
