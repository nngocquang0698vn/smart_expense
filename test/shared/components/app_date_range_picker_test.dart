import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:smart_expense/core/utils/date_format.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/shared/components/app_date_range_picker.dart";

void main() {
  setUpAll(() async {
    await initializeDateFormatting("vi");
  });

  testWidgets("shows not-selected subtitle when range empty", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          const ThemeSettings(),
          brightness: Brightness.light,
        ),
        home: Scaffold(body: AppDateRangePicker(onChanged: (_) {})),
      ),
    );

    expect(find.text(AppLocalizations.vi.dateRangeNotSelected), findsOneWidget);
  });

  testWidgets("shows formatted range when start and end set", (tester) async {
    final start = DateTime(2026, 5, 1);
    final end = DateTime(2026, 5, 16);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          const ThemeSettings(),
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: AppDateRangePicker(
            startDate: start,
            endDate: end,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    final expected =
        "${formatTransactionDate(start)} – ${formatTransactionDate(end)}";
    expect(find.text(expected), findsOneWidget);
  });

  testWidgets("clear button calls onChanged with null", (tester) async {
    DateTimeRange? result;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          const ThemeSettings(),
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: AppDateRangePicker(
            startDate: DateTime(2026, 5, 1),
            endDate: DateTime(2026, 5, 10),
            onChanged: (r) => result = r,
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppLocalizations.vi.dateRangeClear));
    await tester.pump();
    expect(result, isNull);
  });
}
