import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:smart_expense/core/utils/date_format.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/shared/components/app_date_picker.dart";

void main() {
  setUpAll(() async {
    await initializeDateFormatting("vi");
  });

  testWidgets("AppDatePicker listTile shows formatted transaction date", (
    tester,
  ) async {
    final date = DateTime(2026, 5, 16);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          const ThemeSettings(),
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: AppDatePicker(
            date: date,
            style: AppDatePickerStyle.listTile,
            onDateChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text(formatTransactionDateLong(date)), findsOneWidget);
    expect(find.text(AppLocalizations.vi.transactionDate), findsOneWidget);
  });

  testWidgets("AppDatePicker card style shows short date format", (
    tester,
  ) async {
    final date = DateTime(2026, 5, 16);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppDatePicker(
            date: date,
            style: AppDatePickerStyle.card,
            onDateChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text(formatTransactionDate(date)), findsOneWidget);
  });

  testWidgets("AppDatePicker does not open picker when disabled", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(
          const ThemeSettings(),
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: AppDatePicker(
            date: DateTime(2026, 5, 16),
            enabled: false,
            onDateChanged: (_) {},
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsNothing);
  });
}
