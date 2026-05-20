import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/shared/components/form_amount_field.dart";

void main() {
  Widget buildSubject({required bool isIncome}) {
    return ProviderScope(
      child: MaterialApp(
        home: Scaffold(
          body: FormAmountField(initialAmount: 1000, isIncome: isIncome),
        ),
      ),
    );
  }

  testWidgets("shows plus sign for income amount", (tester) async {
    await tester.pumpWidget(buildSubject(isIncome: true));

    expect(find.text("+ "), findsOneWidget);
    expect(find.text("1.000"), findsOneWidget);
    expect(find.text(" đ"), findsOneWidget);
  });

  testWidgets("shows minus sign for expense amount", (tester) async {
    await tester.pumpWidget(buildSubject(isIncome: false));

    expect(find.text("- "), findsOneWidget);
    expect(find.text("1.000"), findsOneWidget);
    expect(find.text(" đ"), findsOneWidget);
  });
}
