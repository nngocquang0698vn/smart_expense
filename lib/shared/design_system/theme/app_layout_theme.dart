import "package:flutter/material.dart";

import "package:smart_expense/app/theme/theme_settings.dart";

/// Layout-level colours that depend on [ThemeSettings.useColoredSurfaces].
///
/// [ColorScheme.surface] from Material is always seed-tinted; the toggle must
/// still produce a **visible** difference — mainly the desktop content panel
/// and (via [ThemeData.scaffoldBackgroundColor]) the outer shell.
@immutable
class AppLayoutTheme extends ThemeExtension<AppLayoutTheme> {
  const AppLayoutTheme({required this.desktopContentColor});

  /// Desktop: large rounded panel behind [IndexedStack] (right of sidebar).
  final Color desktopContentColor;

  factory AppLayoutTheme.compute(
    ThemeSettings settings,
    ColorScheme scheme,
    Brightness brightness,
  ) {
    if (!settings.effectiveColoredSurfaces) {
      return AppLayoutTheme(desktopContentColor: scheme.surface);
    }
    final a = brightness == Brightness.dark ? 0.14 : 0.10;
    return AppLayoutTheme(
      desktopContentColor: Color.alphaBlend(
        settings.effectiveSeedColor.withValues(alpha: a),
        scheme.surface,
      ),
    );
  }

  @override
  AppLayoutTheme copyWith({Color? desktopContentColor}) {
    return AppLayoutTheme(
      desktopContentColor: desktopContentColor ?? this.desktopContentColor,
    );
  }

  @override
  ThemeExtension<AppLayoutTheme> lerp(
    ThemeExtension<AppLayoutTheme>? other,
    double t,
  ) {
    if (other is! AppLayoutTheme) return this;
    return AppLayoutTheme(
      desktopContentColor: Color.lerp(
        desktopContentColor,
        other.desktopContentColor,
        t,
      )!,
    );
  }
}
