import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/reports/domain/report_calculations.dart";

void main() {
  group("ReportCalculations.categoryShare", () {
    test("returns 0 when total is 0", () {
      expect(ReportCalculations.categoryShare(50_000, 0), 0);
    });

    test("returns 0 when amount is 0 or negative", () {
      expect(ReportCalculations.categoryShare(0, 100_000), 0);
      expect(ReportCalculations.categoryShare(-1, 100_000), 0);
    });

    test("computes correct share for normal amounts", () {
      expect(ReportCalculations.categoryShare(25_000, 100_000), 0.25);
    });

    test("handles large VND totals without precision loss for display", () {
      const amount = 999999999999;
      const total = 1999999999998;
      final share = ReportCalculations.categoryShare(amount, total);
      expect(share, closeTo(0.5, 0.0001));
      expect(ReportCalculations.categoryPercent(amount, total), closeTo(50, 0.01));
    });
  });

  group("ReportCalculations.chartSectionValue", () {
    test("never returns negative chart values", () {
      expect(ReportCalculations.chartSectionValue(0), 0);
      expect(ReportCalculations.chartSectionValue(-100), 0);
      expect(ReportCalculations.chartSectionValue(1000), 1000);
    });
  });
}
