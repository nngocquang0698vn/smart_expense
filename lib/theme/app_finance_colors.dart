import "package:flutter/material.dart";

/// Cashew-style finance semantics — fixed hues that do not follow the seed.
@immutable
class AppFinanceColors extends ThemeExtension<AppFinanceColors> {
  const AppFinanceColors({
    required this.incomeAmount,
    required this.expenseAmount,
    required this.dangerAction,
    required this.fieldText,
    required this.textHint,
    required this.textMuted,
    required this.fieldFill,
    required this.sheetBackground,
    required this.fieldBorder,
  });

  final Color incomeAmount;
  final Color expenseAmount;

  /// Delete / destructive actions on dark surfaces (brighter than [expenseAmount]).
  final Color dangerAction;

  /// Typed value inside inputs (Cashew `black` → white in dark).
  final Color fieldText;

  /// Labels & placeholders inside fields.
  final Color textHint;

  /// Subtitles, helper lines, list secondary text.
  final Color textMuted;

  final Color fieldFill;
  final Color sheetBackground;
  final Color fieldBorder;

  factory AppFinanceColors.forBrightness(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return const AppFinanceColors(
        incomeAmount: Color(0xFF62CA77),
        expenseAmount: Color(0xFFDA7272),
        dangerAction: Color(0xFFEE8A8A),
        fieldText: Color(0xFFF2F4F7),
        textHint: Color(0xFF9CA3AF),
        textMuted: Color(0xFFB8C0CC),
        fieldFill: Color(0xFF2C2C2C),
        sheetBackground: Color(0xFF161616),
        fieldBorder: Color(0xFF505050),
      );
    }
    return const AppFinanceColors(
      incomeAmount: Color(0xFF59A849),
      expenseAmount: Color(0xFFCA5A5A),
      dangerAction: Color(0xFFC24E4E),
      fieldText: Color(0xFF111827),
      textHint: Color(0xFF6B7280),
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
    Color? dangerAction,
    Color? fieldText,
    Color? textHint,
    Color? textMuted,
    Color? fieldFill,
    Color? sheetBackground,
    Color? fieldBorder,
  }) {
    return AppFinanceColors(
      incomeAmount: incomeAmount ?? this.incomeAmount,
      expenseAmount: expenseAmount ?? this.expenseAmount,
      dangerAction: dangerAction ?? this.dangerAction,
      fieldText: fieldText ?? this.fieldText,
      textHint: textHint ?? this.textHint,
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
      dangerAction: Color.lerp(dangerAction, other.dangerAction, t)!,
      fieldText: Color.lerp(fieldText, other.fieldText, t)!,
      textHint: Color.lerp(textHint, other.textHint, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      fieldFill: Color.lerp(fieldFill, other.fieldFill, t)!,
      sheetBackground: Color.lerp(sheetBackground, other.sheetBackground, t)!,
      fieldBorder: Color.lerp(fieldBorder, other.fieldBorder, t)!,
    );
  }
}

extension AppFinanceColorsContext on BuildContext {
  AppFinanceColors get financeColors =>
      Theme.of(this).extension<AppFinanceColors>() ??
      AppFinanceColors.forBrightness(Theme.of(this).brightness);
}
