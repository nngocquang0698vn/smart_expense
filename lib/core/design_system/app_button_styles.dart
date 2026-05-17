import "package:flutter/material.dart";

import "app_radius.dart";
import "app_spacing.dart";
import "app_tinted_surface.dart";
import "app_typography.dart";

/// Shared [ButtonStyle] presets — use instead of ad-hoc colours in widgets.
abstract final class AppButtonStyles {
  /// Secondary action on tinted media cards — white fill, primary text + border.
  static ButtonStyle tintedCardSecondary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = AppTintedSurface.actionForeground(scheme);
    return OutlinedButton.styleFrom(
      foregroundColor: fg,
      backgroundColor: AppTintedSurface.actionFill(scheme),
      disabledForegroundColor: fg.withValues(alpha: 0.38),
      disabledBackgroundColor: AppTintedSurface.actionFill(scheme),
      side: BorderSide(color: fg.withValues(alpha: 0.45), width: 1.5),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      textStyle: const TextStyle(
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.semibold,
      ),
    );
  }

  /// Primary action on tinted media cards — solid brand, high contrast.
  static ButtonStyle tintedCardPrimary(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = AppTintedSurface.actionPrimaryForeground(scheme);
    final bg = AppTintedSurface.actionPrimaryFill(scheme);
    return FilledButton.styleFrom(
      foregroundColor: fg,
      backgroundColor: bg,
      disabledForegroundColor: fg.withValues(alpha: 0.38),
      disabledBackgroundColor: bg.withValues(alpha: 0.45),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      textStyle: const TextStyle(
        fontSize: AppTypography.bodySmall,
        fontWeight: AppTypography.bold,
      ),
    );
  }
}
