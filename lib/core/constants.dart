import "package:flutter/material.dart";

export "design_system/app_button_styles.dart";
export "design_system/app_breakpoints.dart";
export "design_system/app_colors.dart";
export "design_system/app_durations.dart";
export "design_system/app_elevation.dart";
export "design_system/app_radius.dart";
export "design_system/app_shadows.dart";
export "design_system/app_spacing.dart";
export "design_system/app_tinted_surface.dart";
export "design_system/app_typography.dart";

import "design_system/app_spacing.dart";

abstract final class AppInsets {
  static const double screenH = AppSpacing.md;
  static const double listBottom = 96;

  static const EdgeInsets cardPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.sm,
    vertical: AppSpacing.xs,
  );

  static const EdgeInsets cardMargin = EdgeInsets.symmetric(
    horizontal: AppSpacing.md,
    vertical: AppSpacing.xxs,
  );

  static const EdgeInsets sectionHeader = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.sm,
    AppSpacing.md,
    4,
  );

  static const EdgeInsets dayHeader = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.sm,
    AppSpacing.md,
    4,
  );
}

abstract final class AppPageSizes {
  static const int historyPage = 20;
  static const double scrollLoadThreshold = 200;
}
