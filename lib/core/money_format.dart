import "package:intl/intl.dart";

final _commaFormatter = NumberFormat("#,###", "en_US");

/// Comma-grouped VND amount without symbol (e.g. `1,234,567`).
String formatMoneyDigits(int amountVnd) => _commaFormatter.format(amountVnd);

/// Formatted VND for lists, summaries, and tiles (e.g. `1,234,567 ₫`).
String formatMoneyVi(int amountVnd) => "${formatMoneyDigits(amountVnd)} ₫";
