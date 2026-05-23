/// Pure helpers for report percentages and chart values.
abstract final class ReportCalculations {
  /// Share of [amount] in [total], in range `0.0`…`1.0`. Never divides by zero.
  static double categoryShare(int amount, int total) {
    if (total <= 0 || amount <= 0) return 0;
    return amount / total;
  }

  /// Percent in range `0.0`…`100.0` for labels and donut center.
  static double categoryPercent(int amount, int total) =>
      categoryShare(amount, total) * 100;

  /// Safe chart section value (non-negative).
  static double chartSectionValue(int amount) =>
      amount > 0 ? amount.toDouble() : 0;
}
