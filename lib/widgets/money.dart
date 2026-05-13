import "package:flutter/widgets.dart";
import "package:intl/intl.dart";

String formatMoneyVi(int amountVnd) {
  final f = NumberFormat.currency(locale: "vi_VN", symbol: "₫", decimalDigits: 0);
  return f.format(amountVnd);
}

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
    Color? color;
    if (isIncome != null) {
      color = isIncome! ? const Color(0xFF059669) : const Color(0xFFDC2626);
    }
    final prefix = isIncome == true ? "+" : (isIncome == false ? "−" : "");
    return Text(
      "$prefix${formatMoneyVi(amountVnd)}",
      style: base.copyWith(color: color ?? base.color),
    );
  }
}
