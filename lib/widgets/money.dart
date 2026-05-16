import "package:flutter/material.dart";
import "package:intl/intl.dart";

import "../theme/app_finance_colors.dart";

final _vndFormatter = NumberFormat.currency(
  locale: "vi_VN",
  symbol: "₫",
  decimalDigits: 0,
);

String formatMoneyVi(int amountVnd) => _vndFormatter.format(amountVnd);

/// Monetary amount with Cashew-style fixed income/expense colours.
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
    final finance = context.financeColors;
    final base = style ?? DefaultTextStyle.of(context).style;
    final Color? color = switch (isIncome) {
      true => finance.incomeAmount,
      false => finance.expenseAmount,
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
