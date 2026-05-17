import "package:flutter/material.dart";

/// Per-theme "chrome" colours for surfaces that must feel cohesive with the
/// user's accent seed but are **not** well served by raw [ColorScheme] slots
/// (e.g. `primaryContainer` can look muddy or shift hue on some seeds).
///
/// Registered on [ThemeData.extensions] from [AppTheme.build]. Widgets read it
/// via `Theme.of(context).extension<AppChromeTheme>()`.
@immutable
class AppChromeTheme extends ThemeExtension<AppChromeTheme> {
  const AppChromeTheme({
    required this.sidebarGradientTop,
    required this.sidebarGradientMid,
    required this.sidebarGradientBottom,
    required this.sidebarBorder,
    required this.sidebarShadow,
    required this.sidebarNavInactive,
  });

  /// Airy highlight — almost white with a whisper of the seed hue.
  final Color sidebarGradientTop;

  /// Middle stop so the gradient does not band harshly.
  final Color sidebarGradientMid;

  /// Slightly deeper pastel — still soft, not "container mud".
  final Color sidebarGradientBottom;

  /// Subtle edge to separate the sidebar from the shell background.
  final Color sidebarBorder;

  /// Soft shadow tied to the shell / seed.
  final Color sidebarShadow;

  /// Inactive nav labels/icons on the sidebar rail.
  final Color sidebarNavInactive;

  /// Builds chrome from the user-selected **seed** and [brightness].
  factory AppChromeTheme.fromSeed(Color seed, Brightness brightness) {
    return brightness == Brightness.dark
        ? _fromSeedDark(seed)
        : _fromSeedLight(seed);
  }

  static AppChromeTheme _fromSeedLight(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    final isNeutral = hsl.saturation < 0.08;

    if (isNeutral) {
      return const AppChromeTheme(
        sidebarGradientTop: Color(0xFFF8F9FB),
        sidebarGradientMid: Color(0xFFEEF1F5),
        sidebarGradientBottom: Color(0xFFE3E8EE),
        sidebarBorder: Color(0xFFD8DEE6),
        sidebarShadow: Color(0x1A64748B),
        sidebarNavInactive: Color(0xFF475569),
      );
    }

    final h = hsl.hue;
    final satTop = (hsl.saturation * 0.30).clamp(0.07, 0.36);
    final satMid = (hsl.saturation * 0.36).clamp(0.09, 0.42);
    final satBot = (hsl.saturation * 0.44).clamp(0.11, 0.50);

    final top = HSLColor.fromAHSL(1.0, h, satTop, 0.978).toColor();
    final mid = HSLColor.fromAHSL(1.0, h, satMid, 0.948).toColor();
    final bottom = HSLColor.fromAHSL(1.0, h, satBot, 0.905).toColor();

    final borderSat = (satBot * 0.55).clamp(0.06, 0.22);
    final border = HSLColor.fromAHSL(1.0, h, borderSat, 0.88).toColor();

    final navSat = (hsl.saturation * 0.75).clamp(0.12, 0.62);
    final navInactive = HSLColor.fromAHSL(1.0, h, navSat, 0.37).toColor();

    return AppChromeTheme(
      sidebarGradientTop: top,
      sidebarGradientMid: mid,
      sidebarGradientBottom: bottom,
      sidebarBorder: border,
      sidebarShadow: seed.withValues(alpha: 0.12),
      sidebarNavInactive: navInactive,
    );
  }

  static AppChromeTheme _fromSeedDark(Color seed) {
    final hsl = HSLColor.fromColor(seed);
    final isNeutral = hsl.saturation < 0.08;

    if (isNeutral) {
      return const AppChromeTheme(
        sidebarGradientTop: Color(0xFF2E323A),
        sidebarGradientMid: Color(0xFF25282E),
        sidebarGradientBottom: Color(0xFF1C1F24),
        sidebarBorder: Color(0xFF3D434D),
        sidebarShadow: Color(0x66000000),
        sidebarNavInactive: Color(0xFFB4BCC8),
      );
    }

    final h = hsl.hue;
    final satTop = (hsl.saturation * 0.22).clamp(0.05, 0.28);
    final satMid = (hsl.saturation * 0.28).clamp(0.08, 0.34);
    final satBot = (hsl.saturation * 0.35).clamp(0.10, 0.40);

    final top = HSLColor.fromAHSL(1.0, h, satTop, 0.19).toColor();
    final mid = HSLColor.fromAHSL(1.0, h, satMid, 0.155).toColor();
    final bottom = HSLColor.fromAHSL(1.0, h, satBot, 0.125).toColor();

    final borderSat = (satBot * 0.45).clamp(0.05, 0.18);
    final border = HSLColor.fromAHSL(1.0, h, borderSat, 0.32).toColor();

    final navSat = (hsl.saturation * 0.28).clamp(0.06, 0.28);
    final navInactive = HSLColor.fromAHSL(1.0, h, navSat, 0.74).toColor();

    return AppChromeTheme(
      sidebarGradientTop: top,
      sidebarGradientMid: mid,
      sidebarGradientBottom: bottom,
      sidebarBorder: border,
      sidebarShadow: Colors.black.withValues(alpha: 0.45),
      sidebarNavInactive: navInactive,
    );
  }

  @override
  AppChromeTheme copyWith({
    Color? sidebarGradientTop,
    Color? sidebarGradientMid,
    Color? sidebarGradientBottom,
    Color? sidebarBorder,
    Color? sidebarShadow,
    Color? sidebarNavInactive,
  }) {
    return AppChromeTheme(
      sidebarGradientTop: sidebarGradientTop ?? this.sidebarGradientTop,
      sidebarGradientMid: sidebarGradientMid ?? this.sidebarGradientMid,
      sidebarGradientBottom:
          sidebarGradientBottom ?? this.sidebarGradientBottom,
      sidebarBorder: sidebarBorder ?? this.sidebarBorder,
      sidebarShadow: sidebarShadow ?? this.sidebarShadow,
      sidebarNavInactive: sidebarNavInactive ?? this.sidebarNavInactive,
    );
  }

  @override
  ThemeExtension<AppChromeTheme> lerp(
    ThemeExtension<AppChromeTheme>? other,
    double t,
  ) {
    if (other is! AppChromeTheme) return this;
    return AppChromeTheme(
      sidebarGradientTop: Color.lerp(
        sidebarGradientTop,
        other.sidebarGradientTop,
        t,
      )!,
      sidebarGradientMid: Color.lerp(
        sidebarGradientMid,
        other.sidebarGradientMid,
        t,
      )!,
      sidebarGradientBottom: Color.lerp(
        sidebarGradientBottom,
        other.sidebarGradientBottom,
        t,
      )!,
      sidebarBorder: Color.lerp(sidebarBorder, other.sidebarBorder, t)!,
      sidebarShadow: Color.lerp(sidebarShadow, other.sidebarShadow, t)!,
      sidebarNavInactive: Color.lerp(
        sidebarNavInactive,
        other.sidebarNavInactive,
        t,
      )!,
    );
  }
}
