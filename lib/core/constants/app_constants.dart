import "package:flutter/material.dart";

export "package:smart_expense/shared/design_system/tokens/app_breakpoints.dart";
export "package:smart_expense/shared/design_system/tokens/app_colors.dart";
export "package:smart_expense/shared/design_system/tokens/app_durations.dart";
export "package:smart_expense/shared/design_system/tokens/app_radius.dart";
export "package:smart_expense/shared/design_system/tokens/app_spacing.dart";
export "package:smart_expense/shared/design_system/tokens/app_typography.dart";

import "package:smart_expense/shared/design_system/tokens/app_spacing.dart";

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
