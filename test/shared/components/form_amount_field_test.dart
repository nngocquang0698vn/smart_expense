import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/shared/components/form_amount_field.dart";
import "package:smart_expense/shared/design_system/theme/app_finance_colors.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";

void main() {
  Widget buildSubject({required bool isIncome}) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FormAmountField(
            initialAmount: 40_000_000,
            isIncome: isIncome,
          ),
        ),
      ),
    );
  }

  testWidgets("shows plus sign for income amount", (tester) async {
    await tester.pumpWidget(buildSubject(isIncome: true));

    expect(find.text("+ "), findsOneWidget);
    expect(find.text("40.000.000"), findsOneWidget);
    expect(find.text(" đ"), findsOneWidget);
  });

  testWidgets("shows minus sign for expense amount", (tester) async {
    await tester.pumpWidget(buildSubject(isIncome: false));

    expect(find.text("- "), findsOneWidget);
    expect(find.text("40.000.000"), findsOneWidget);
  });

  testWidgets("uses green amount color for income", (tester) async {
    await tester.pumpWidget(buildSubject(isIncome: true));

    final amount = tester.widget<Text>(find.text("40.000.000"));
    final finance = AppFinanceColors.forBrightness(Brightness.light);
    expect(amount.style?.color, finance.incomeAmount);
  });

  testWidgets("uses red amount color for expense", (tester) async {
    await tester.pumpWidget(buildSubject(isIncome: false));

    final amount = tester.widget<Text>(find.text("40.000.000"));
    final finance = AppFinanceColors.forBrightness(Brightness.light);
    expect(amount.style?.color, finance.expenseAmount);
  });
}
