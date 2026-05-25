import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/utils/date_range.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";

void main() {
  test("custom date filter includes the whole from-to date range", () {
    final selection = DateFilterSelection(
      preset: DateFilterPreset.custom,
      custom: AppDateRange(
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 10),
      ),
    );

    final range = selection.resolveRange(DateTime(2026, 5, 25, 12));

    expect(range.contains(DateTime(2026, 5, 1)), isTrue);
    expect(range.contains(DateTime(2026, 5, 10, 23, 59, 59, 999, 999)), isTrue);
    expect(range.contains(DateTime(2026, 5, 11)), isFalse);
  });

  test("custom analytics period includes the whole to date", () {
    final range = AnalyticsPeriod.custom.resolve(
      DateTime(2026, 5, 25, 12),
      custom: AppDateRange(
        start: DateTime(2026, 5, 1),
        end: DateTime(2026, 5, 10),
      ),
    );

    expect(range.start, DateTime(2026, 5, 1));
    expect(range.contains(DateTime(2026, 5, 10, 23, 59, 59, 999, 999)), isTrue);
    expect(range.contains(DateTime(2026, 5, 11)), isFalse);
  });
}
