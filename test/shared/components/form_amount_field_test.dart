import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/shared/components/form_amount_field.dart";
import "package:smart_expense/shared/design_system/theme/app_finance_colors.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";

void main() {
  Widget buildSubject({
    required bool isIncome,
    int initialAmount = 40_000_000,
    bool autofocus = false,
    VoidCallback? onDone,
    VoidCallback? onTap,
  }) {
    return ProviderScope(
      child: MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: FormAmountField(
            initialAmount: initialAmount,
            isIncome: isIncome,
            autofocus: autofocus,
            onDone: onDone,
            onTap: onTap,
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

  testWidgets("physical digit keys update amount when focused", (tester) async {
    await tester.pumpWidget(
      buildSubject(isIncome: false, initialAmount: 0, autofocus: true),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.digit1);
    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.sendKeyEvent(LogicalKeyboardKey.numpad3);
    await tester.pump();

    expect(find.text("123"), findsOneWidget);
  });

  testWidgets("tap requests focus so physical digit keys work", (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      buildSubject(
        isIncome: false,
        initialAmount: 0,
        onTap: () {
          tapped = true;
          FocusManager.instance.primaryFocus?.unfocus();
        },
      ),
    );

    await tester.tap(find.text("0"));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.digit5);
    await tester.pump();

    expect(tapped, isTrue);
    expect(find.text("5"), findsOneWidget);
  });

  testWidgets("physical backspace removes the last raw digit", (tester) async {
    await tester.pumpWidget(
      buildSubject(isIncome: false, initialAmount: 120000, autofocus: true),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pump();

    expect(find.text("12.000"), findsOneWidget);
  });

  testWidgets("physical delete clears the amount", (tester) async {
    await tester.pumpWidget(
      buildSubject(isIncome: false, initialAmount: 120000, autofocus: true),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.delete);
    await tester.pump();

    expect(find.text("0"), findsOneWidget);
  });

  testWidgets("enter and escape call amount done callback", (tester) async {
    var doneCount = 0;
    await tester.pumpWidget(
      buildSubject(
        isIncome: false,
        initialAmount: 0,
        autofocus: true,
        onDone: () => doneCount++,
      ),
    );
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(doneCount, 2);
  });
}
