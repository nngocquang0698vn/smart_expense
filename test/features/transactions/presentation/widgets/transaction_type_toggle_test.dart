import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_type_toggle.dart";

void main() {
  testWidgets("TransactionTypeToggle calls onChanged when selection changes", (
    tester,
  ) async {
    var isIncome = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionTypeToggle(
            isIncome: isIncome,
            onChanged: (value) => isIncome = value,
          ),
        ),
      ),
    );

    await tester.tap(find.text(AppLocalizations.vi.income));
    await tester.pumpAndSettle();

    expect(isIncome, isTrue);
  });
}
