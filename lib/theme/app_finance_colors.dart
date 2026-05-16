import "package:flutter/material.dart";

/// Cashew-style finance semantics — fixed hues that do not follow the seed.
///
/// Light/dark values mirror `code-ref/Cashew-main/budget/lib/colors.dart`.
@immutable
class AppFinanceColors extends ThemeExtension<AppFinanceColors> {
  const AppFinanceColors({
    required this.incomeAmount,
    required this.expenseAmount,
    required this.textMuted,
    required this.fieldFill,
    required this.sheetBackground,
    required this.fieldBorder,
  });

  final Color incomeAmount;
  final Color expenseAmount;

  /// Hints, subtitles, secondary lines (Cashew `textLight` — high contrast).
  final Color textMuted;

  /// Input / canvas fill (`canvasContainer` in Cashew).
  final Color fieldFill;

  /// Bottom sheets & dialogs (`lightDarkAccent` in Cashew).
  final Color sheetBackground;

  /// Field outlines (`lightDarkAccentHeavy` in Cashew).
  final Color fieldBorder;

  factory AppFinanceColors.forBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const AppFinanceColors(
        incomeAmount: Color(0xFF62CA77),
        expenseAmount: Color(0xFFDA7272),
        textMuted: Color(0xFFA6AEB8),
        fieldFill: Color(0xFF242424),
        sheetBackground: Color(0xFF161616),
        fieldBorder: Color(0xFF444444),
      );
    }
    return const AppFinanceColors(
      incomeAmount: Color(0xFF59A849),
      expenseAmount: Color(0xFFCA5A5A),
      textMuted: Color(0xFF6B7280),
      fieldFill: Color(0xFFFFFFFF),
      sheetBackground: Color(0xFFFFFFFF),
      fieldBorder: Color(0xFFE5E7EB),
    );
  }

  @override
  AppFinanceColors copyWith({
    Color? incomeAmount,
    Color? expenseAmount,
    Color? textMuted,
    Color? fieldFill,
    Color? sheetBackground,
    Color? fieldBorder,
  }) {
    return AppFinanceColors(
      incomeAmount: incomeAmount ?? this.incomeAmount,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      textMuted: textMuted ?? this.textMuted,
      fieldFill: fieldFill ?? this.fieldFill,
      sheetBackground: sheetBackground ?? this.sheetBackground,
      fieldBorder: fieldBorder ?? this.fieldBorder,
    );
  }

  @override
  AppFinanceColors lerp(ThemeExtension<AppFinanceColors>? other, double t) {
    if (other is! AppFinanceColors) return this;
    return AppFinanceColors(
      incomeAmount: Color.lerp(incomeAmount, other.incomeAmount, t)!,
      expenseAmount: Color.lerp(expenseAmount, other.expenseAmount, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      sheetBackground:
          Color.lerp(sheetBackground, other.sheetBackground, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
    );
  }
}

extension AppFinanceColorsContext on BuildContext {
  AppFinanceColors get financeColors =>
      Theme.of(this).extension<AppFinanceColors>() ??
      AppFinanceColors.forBrightness(Theme.of(this).brightness);
}
