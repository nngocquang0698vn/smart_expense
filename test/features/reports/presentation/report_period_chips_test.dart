import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:intl/date_symbol_data_local.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/features/reports/application/report_controller.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";
import "package:smart_expense/features/reports/presentation/widgets/report_period_chips.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";

void main() {
  setUpAll(() async {
    await initializeDateFormatting("vi");
  });

  testWidgets("tapping selected custom period opens range picker again", (
    tester,
  ) async {
    var customPickCount = 0;
    AnalyticsPeriod? selectedPeriod;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.build(
          const ThemeSettings(),
          brightness: Brightness.light,
        ),
        home: Scaffold(
          body: ReportPeriodChips(
            state: ReportState(
              period: AnalyticsPeriod.custom,
              customRange: DateTimeRange(
                start: DateTime(2026, 5, 1),
                end: DateTime(2026, 5, 10),
              ),
              incomeSide: false,
              viewModel: const ReportViewModel.empty(),
              loading: false,
            ),
            onPeriodSelected: (period) async => selectedPeriod = period,
            onCustomRangePick: () async => customPickCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ChoiceChip).last);
    await tester.pump();

    expect(customPickCount, 1);
    expect(selectedPeriod, isNull);
  });
}
