import "package:flutter/widgets.dart";
import "package:intl/intl.dart";

import "../core/constants.dart";

// Cached formatter — creating NumberFormat is expensive; reuse across frames.
final _vndFormatter = NumberFormat.currency(
  locale: "vi_VN",
  symbol: "₫",
  decimalDigits: 0,
);

/// Formats [amountVnd] as a Vietnamese-locale currency string, e.g. `50.000 ₫`.
String formatMoneyVi(int amountVnd) => _vndFormatter.format(amountVnd);

/// Displays a monetary amount with optional income/expense colouring.
///
/// When [isIncome] is `true` the amount is prefixed with "+" and rendered in
/// [AppColors.income] green. `false` uses "−" and [AppColors.expense] red.
/// `null` renders with no prefix or colour override.
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.amountVnd, {
    super.key,
    this.style,
    this.isIncome,
  });

  final int amountVnd;
  final TextStyle? style;
  final bool? isIncome;

  @override
  Widget build(BuildContext context) {
    final base = style ?? DefaultTextStyle.of(context).style;
    final Color? color = switch (isIncome) {
      true => AppColors.income,
      false => AppColors.expense,
      null => null,
    };
    final prefix = switch (isIncome) {
      true => "+",
      false => "−",
      null => "",
    };
    return Text(
      "$prefix${formatMoneyVi(amountVnd)}",
      style: base.copyWith(color: color ?? base.color),
    );
  }
}
