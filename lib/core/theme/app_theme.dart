import "package:flutter/material.dart";

import "../constants.dart";
import "../theme_settings.dart";
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

    final seed = settings.effectiveSeedColor;
    final tinted = settings.effectiveColoredSurfaces;

    final seededScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
    );
    final scheme = seededScheme.copyWith(
      primary: seed,
      secondary: AppColors.brandYellow,
      error: AppColors.error,
    );

    final scaffoldBg = isDark
        ? (tinted
              ? Color.alphaBlend(
                  seed.withValues(alpha: 0.18),
                  AppColors.darkBackground,
                )
              : AppColors.darkBackground)
        : (tinted
              ? Color.alphaBlend(
                  seed.withValues(alpha: 0.08),
                  AppColors.background,
                )
              : AppColors.background);

    final cardBg = isDark
        ? (tinted
              ? Color.alphaBlend(
                  seed.withValues(alpha: 0.08),
                  AppColors.darkSurface,
                )
              : AppColors.darkSurface)
        : (tinted
              ? Color.alphaBlend(
                  seed.withValues(alpha: 0.04),
                  AppColors.surface,
                )
              : AppColors.surface);

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
    );

    final cardRadius = BorderRadius.circular(AppRadius.xl);
    final inputRadius = BorderRadius.circular(AppRadius.lg);
    final sheetRadius = BorderRadius.circular(AppRadius.sheet);

    final chrome = AppChromeTheme.fromSeed(seed, brightness);
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
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        foregroundColor: isDark
            ? AppColors.darkTextPrimary
            : AppColors.textPrimary,
        titleTextStyle: TextStyle(
          color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
          fontSize: AppTypography.title,
          fontWeight: AppTypography.bold,
        ),
      ),

      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: cardRadius),
        color: cardBg,
        margin: EdgeInsets.zero,
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: finance.fieldFill,
        labelStyle: TextStyle(color: finance.textHint),
        floatingLabelStyle: TextStyle(
          color: finance.fieldText,
          fontWeight: FontWeight.w600,
        ),
        hintStyle: TextStyle(color: finance.textHint),
        prefixStyle: TextStyle(
          color: finance.fieldText,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
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
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: inputRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: finance.fieldBorder),
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: inputRadius),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
      ),
    );
  }
}
