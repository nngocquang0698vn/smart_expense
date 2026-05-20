import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/tokens/app_spacing.dart";

/// Chiều cao hàng nút onboarding (Trước/Tiếp hoặc Quay lại/Bắt đầu).
const double kOnboardingBottomButtonHeight = 40;

/// Khoảng cách từ nội dung PageView xuống ô nhập tên.
const double kOnboardingNameFieldTopGap = AppSpacing.md;

/// Khoảng cách từ ô nhập tên xuống thanh chấm tiến trình.
const double kOnboardingNameFieldToDotsGap = AppSpacing.md;

/// Khoảng cách từ thanh chấm xuống hàng nút.
const double kOnboardingDotsToButtonsGap = AppSpacing.sm;

/// Chiều cao thanh chấm (chấm 8px).
const double kOnboardingProgressDotSize = 8;

/// Ước lượng chiều cao [TextField] tên (khớp [InputDecorationTheme]).
double onboardingNameTextFieldHeight(BuildContext context) {
  final theme = Theme.of(context).inputDecorationTheme;
  final resolvedPadding =
      theme.contentPadding?.resolve(Directionality.of(context)) ??
      const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      );
  final textStyle = Theme.of(context).textTheme.bodyLarge;
  final painter = TextPainter(
    text: TextSpan(text: "Mg", style: textStyle),
    textDirection: Directionality.of(context),
  )..layout();
  return painter.height + resolvedPadding.vertical + 16;
}

/// Tổng chiều cao vùng dưới PageView khi có ô tên (dùng giữ chỗ ở các trang trước).
double onboardingNameSectionHeight(BuildContext context) {
  return onboardingNameTextFieldHeight(context) +
      kOnboardingNameFieldTopGap +
      kOnboardingNameFieldToDotsGap;
}

/// Tổng chiều cao footer dưới PageView (ô tên + chấm + nút + padding).
double onboardingFooterHeight(BuildContext context) {
  return onboardingNameSectionHeight(context) +
      kOnboardingProgressDotSize +
      kOnboardingDotsToButtonsGap +
      kOnboardingBottomButtonHeight +
      AppSpacing.md;
}
