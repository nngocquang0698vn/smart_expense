import "package:flutter/material.dart";

import "package:smart_expense/shared/design_system/tokens/app_colors.dart";

/// Tokens cho toggle Chi tiêu/Thu nhập và thẻ Thêm nhanh (Stitch Emerald Trust).
abstract final class AppTransactionEntryTokens {
  /// Nền track segmented toggle (surface-container-low).
  static const Color toggleTrackLight = Color(0xFFE6F6FF);

  static const Color toggleTrackDark = Color(0xFF1A3338);

  /// Nền nửa đang chọn — xanh lá đậm (Stitch).
  static const Color toggleSelectedFillLight = AppColors.brandGreenDark;

  static const Color toggleSelectedFillDark = AppColors.brandGreen;

  /// Chữ trên nền xanh đang chọn.
  static const Color toggleSelectedLabelLight = Color(0xFFFFFFFF);

  static const Color toggleSelectedLabelDark = Color(0xFFFFFFFF);

  /// Chữ mục chưa chọn.
  static const Color toggleUnselectedLabelLight = AppColors.textPrimary;

  static const Color toggleUnselectedLabelDark = AppColors.darkTextSecondary;

  /// Nền thẻ tùy chọn Thêm nhanh — cùng tông, không dùng primary đặc.
  static const Color quickAddCardLight = Color(0xFFE6F6FF);

  static const Color quickAddCardDark = Color(0xFF1E333C);

  /// Chữ phụ trên thẻ Thêm nhanh.
  static const Color quickAddSubtitleLight = AppColors.textSecondary;

  static const Color quickAddSubtitleDark = AppColors.darkTextSecondary;

  static Color toggleTrack(Brightness brightness) =>
      brightness == Brightness.dark ? toggleTrackDark : toggleTrackLight;

  static Color toggleSelectedFill(Brightness brightness) =>
      brightness == Brightness.dark
      ? toggleSelectedFillDark
      : toggleSelectedFillLight;

  static Color toggleSelectedLabel(Brightness brightness) =>
      brightness == Brightness.dark
      ? toggleSelectedLabelDark
      : toggleSelectedLabelLight;

  static Color toggleUnselectedLabel(Brightness brightness) =>
      brightness == Brightness.dark
      ? toggleUnselectedLabelDark
      : toggleUnselectedLabelLight;

  static Color quickAddCard(Brightness brightness) =>
      brightness == Brightness.dark ? quickAddCardDark : quickAddCardLight;

  static Color quickAddSubtitle(Brightness brightness) =>
      brightness == Brightness.dark
      ? quickAddSubtitleDark
      : quickAddSubtitleLight;
}
