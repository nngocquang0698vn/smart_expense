import "package:flutter/material.dart";

import "../core/constants.dart";
import "../core/theme_settings.dart";
import "app_chrome_theme.dart";

/// Generates the app's [ThemeData] from a [ThemeSettings] snapshot.
///
/// **Border radii** ([AppRadius]): small 12 · input 16 · card 20 · sheet 24.
abstract final class AppTheme {
  /// Convenience: default settings, light brightness.
  static ThemeData light() => build(const ThemeSettings(), brightness: Brightness.light);

  /// Builds [ThemeData] for [brightness] (light or dark).
  ///
  /// Called whenever [ThemeNotifier] updates — keep it fast (no I/O).
  static ThemeData build(
    ThemeSettings settings, {
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: settings.seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    final scaffoldBg = isDark
        ? (settings.useColoredSurfaces
            ? Color.alphaBlend(
                settings.seedColor.withValues(alpha: 0.14),
                const Color(0xFF121212),
              )
            : const Color(0xFF121212))
        : (settings.useColoredSurfaces
            ? Color.alphaBlend(
                settings.seedColor.withValues(alpha: 0.06),
                Colors.white,
              )
            : const Color(0xFFF7F8FA));

    final cardBg = isDark ? scheme.surfaceContainerLow : Colors.white;
    final appBarBg = isDark ? scheme.surface : Colors.white;
    final inputFill = isDark ? scheme.surfaceContainerHighest : Colors.white;
    final sheetDialogBg = isDark ? scheme.surface : Colors.white;

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );

    final cardRadius = BorderRadius.circular(AppRadius.card);
    final inputRadius = BorderRadius.circular(AppRadius.input);
    final sheetRadius = BorderRadius.circular(AppRadius.sheet);

    final chrome = AppChromeTheme.fromSeed(settings.seedColor, brightness);

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      extensions: <ThemeExtension<dynamic>>[chrome],

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: appBarBg,
        foregroundColor: isDark ? scheme.onSurface : scheme.primary,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        color: cardBg,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(borderRadius: inputRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: sheetDialogBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        showDragHandle: true,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: sheetRadius),
        backgroundColor: sheetDialogBg,
      ),

      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        side: BorderSide.none,
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: inputRadius),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.outlineVariant),
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: inputRadius),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
        ),
      ),
    );
  }
}
