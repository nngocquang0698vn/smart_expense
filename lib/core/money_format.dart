import "package:intl/intl.dart";

final _displayFormatter = NumberFormat("#,###", "en_US");

/// Comma-grouped VND amount without symbol (e.g. `1,250,000`).
String formatMoneyDigits(int amountVnd) => _displayFormatter.format(amountVnd);

/// Formatted VND for lists, summaries, and tiles (e.g. `1,250,000 ₫`).
String formatMoneyVi(int amountVnd) => "${formatMoneyDigits(amountVnd)} ₫";
