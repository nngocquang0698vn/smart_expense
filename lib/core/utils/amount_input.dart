import "package:smart_expense/core/utils/money_format.dart";

/// Maximum storable amount (VND, whole units).
const int kMaxAmountVnd = 999999999999;

/// Display for amount entry fields — same grouping as [formatMoneyDigits].
String formatAmountInput(int amountVnd) => formatMoneyDigits(amountVnd);

/// Parse digits from legacy text controllers or pasted input.
int parseAmountDigits(String text) {
  final raw = text.replaceAll(RegExp(r"[^\d]"), "");
  if (raw.isEmpty) return 0;
  final parsed = int.tryParse(raw) ?? 0;
  return parsed.clamp(0, kMaxAmountVnd);
}
