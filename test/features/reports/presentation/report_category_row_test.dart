import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/core/utils/formatters/money.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";
import "package:smart_expense/features/reports/presentation/widgets/report_category_row.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";

void main() {
  testWidgets("ReportCategoryRow shows name and amount without progress bar", (
    tester,
  ) async {
    var tapped = false;
    const category = LedgerCategory(
      id: "food",
      name: "Ăn uống",
      iconKey: "restaurant",
      colorValue: 0xFF006B68,
      isIncome: false,
    );
    const slice = ReportCategorySlice(
      id: "food",
      amount: 120_000,
      category: category,
    );

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ReportCategoryRow(
            slice: slice,
            isIncome: false,
            highlighted: false,
            selected: false,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text("Ăn uống"), findsOneWidget);
    expect(find.textContaining("120.000"), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    await tester.tap(find.byType(ReportCategoryRow));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
