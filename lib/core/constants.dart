import "package:flutter/material.dart";

export "tokens/app_breakpoints.dart";
export "tokens/app_colors.dart";
export "tokens/app_durations.dart";
export "tokens/app_radius.dart";
export "tokens/app_spacing.dart";
export "tokens/app_typography.dart";

import "tokens/app_spacing.dart";

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
