import "package:flutter_test/flutter_test.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:smart_expense/core/date_format.dart";

void main() {
  setUpAll(() async {
    await initializeDateFormatting("vi");
  });

  final sample = DateTime(2026, 5, 17, 14, 30);

  test("formatTransactionDate uses dd/MM/yyyy", () {
    expect(formatTransactionDate(sample), "17/05/2026");
  });

  test("formatReportAxis uses dd/MM", () {
    expect(formatReportAxis(sample), "17/05");
  });

  test("formatQuickEntryTimestamp uses dd/MM HH:mm", () {
    expect(formatQuickEntryTimestamp(sample), "17/05 14:30");
  });

  test("formatShellTime uses HH:mm", () {
    expect(formatShellTime(sample), "14:30");
  });
}
