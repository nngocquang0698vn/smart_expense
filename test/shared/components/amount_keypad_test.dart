import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/shared/components/amount_keypad.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";

void main() {
  testWidgets("custom keypad buttons dispatch amount actions", (tester) async {
    final digits = <int>[];
    var tripleZeroCount = 0;
    var backspaceCount = 0;
    var doneCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: AmountKeypad(
            onDigit: digits.add,
            onTripleZero: () => tripleZeroCount++,
            onBackspace: () => backspaceCount++,
            onDone: () => doneCount++,
          ),
        ),
      ),
    );

    await tester.tap(find.text("1"));
    await tester.tap(find.text("0"));
    await tester.tap(find.text("000"));
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.tap(find.text("Xong"));
    await tester.pump();

    expect(digits, [1, 0]);
    expect(tripleZeroCount, 1);
    expect(backspaceCount, 1);
    expect(doneCount, 1);
  });
}
