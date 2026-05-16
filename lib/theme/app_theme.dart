import "package:flutter/material.dart";

import "../core/constants.dart";
import "../core/theme_settings.dart";
import "app_chrome_theme.dart";
import "app_finance_colors.dart";
import "app_layout_theme.dart";

/// Generates the app's [ThemeData] from a [ThemeSettings] snapshot.
///
/// Finance surfaces & money colours follow Cashew (`AppFinanceColors`):
/// dark sheet `#161616`, fields `#242424`, fixed income/expense greens/reds.
abstract final class AppTheme {
  static ThemeData light() =>
      build(const ThemeSettings(), brightness: Brightness.light);

  static ThemeData build(
    ThemeSettings settings, {
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final finance = AppFinanceColors.forBrightness(brightness);

    final scheme = ColorScheme.fromSeed(
      seedColor: settings.seedColor,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );

    final scaffoldBg = isDark
        ? (settings.useColoredSurfaces
            ? Color.alphaBlend(
                settings.seedColor.withValues(alpha: 0.18),
                Colors.black,
              )
            : Colors.black)
        : (settings.useColoredSurfaces
            ? Color.alphaBlend(
                settings.seedColor.withValues(alpha: 0.11),
                const Color(0xFFF3F4F6),
              )
            : const Color(0xFFF7F8FA));

    final cardBg = isDark
        ? (settings.useColoredSurfaces
            ? Color.alphaBlend(
                settings.seedColor.withValues(alpha: 0.08),
                const Color(0xFF1C1C1C),
              )
            : const Color(0xFF1C1C1C))
        : (settings.useColoredSurfaces
            ? Color.alphaBlend(
                settings.seedColor.withValues(alpha: 0.06),
                Colors.white,
              )
            : Colors.white);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
    );

    final cardRadius = BorderRadius.circular(AppRadius.card);
    final inputRadius = BorderRadius.circular(AppRadius.input);
    final sheetRadius = BorderRadius.circular(AppRadius.sheet);

    final chrome = AppChromeTheme.fromSeed(settings.seedColor, brightness);
    final layout = AppLayoutTheme.compute(settings, scheme, brightness);

    final textTheme = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      extensions: <ThemeExtension<dynamic>>[chrome, layout, finance],

      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
        foregroundColor: isDark ? scheme.onSurface : scheme.primary,
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        color: cardBg,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: finance.fieldFill,
        labelStyle: TextStyle(color: finance.textMuted),
        floatingLabelStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: finance.textMuted),
        prefixStyle: TextStyle(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        border: OutlineInputBorder(borderRadius: inputRadius),
        enabledBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: finance.fieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: inputRadius,
          borderSide: BorderSide(color: scheme.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      listTileTheme: ListTileThemeData(
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: finance.textMuted,
        ),
        iconColor: finance.textMuted,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: TextStyle(color: scheme.onSurface),
      ),

      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.onPrimary;
            }
            return scheme.onSurface;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return scheme.primary;
            }
            return Colors.transparent;
          }),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: finance.sheetBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.sheet),
          ),
        ),
        showDragHandle: true,
      ),

      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: sheetRadius),
        backgroundColor: finance.sheetBackground,
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
          side: BorderSide(color: finance.fieldBorder),
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
