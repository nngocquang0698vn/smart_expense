import "package:flutter/material.dart";

import "app_colors.dart";

/// Semantic colours for UI on [ColorScheme.primaryContainer] surfaces
/// (audio recorder, media preview cards, …).
///
/// Do **not** use [ColorScheme.onPrimaryContainer] for actions on white chips —
/// with pastel containers it often fails contrast (see design-system rules).
abstract final class AppTintedSurface {
  /// Text and icons placed directly on the tinted card background.
  static Color onBackground(ColorScheme scheme, Brightness brightness) {
    if (brightness == Brightness.dark) {
      return AppColors.darkTextPrimary;
    }
    return scheme.primary;
  }

  /// Secondary line under titles (status, hints).
  static Color onBackgroundMuted(ColorScheme scheme, Brightness brightness) {
    return onBackground(scheme, brightness).withValues(alpha: 0.72);
  }

  /// Inactive decorative elements (wave bars at rest).
  static Color onBackgroundSubtle(ColorScheme scheme, Brightness brightness) {
    return onBackground(scheme, brightness).withValues(alpha: 0.35);
  }

  /// White chip behind action buttons on tinted cards.
  static Color actionFill(ColorScheme scheme) => scheme.surface;

  /// Secondary action label/icon (e.g. Ghi lại).
  static Color actionForeground(ColorScheme scheme) => scheme.primary;

  /// Primary emphasized action (e.g. Nghe lại).
  static Color actionPrimaryFill(ColorScheme scheme) => scheme.primary;

  static Color actionPrimaryForeground(ColorScheme scheme) => scheme.onPrimary;
}
