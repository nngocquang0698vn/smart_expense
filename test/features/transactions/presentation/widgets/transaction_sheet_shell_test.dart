import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_sheet_shell.dart";

void main() {
  Future<void> pumpHost(WidgetTester tester, Widget sheetChild) async {
    await tester.binding.setSurfaceSize(const Size(360, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showTransactionFormSheet(context, child: sheetChild);
                  },
                  child: const Text("Open"),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text("Open"));
    await tester.pumpAndSettle();
  }

  testWidgets("transaction sheet wraps content when keypad is hidden", (
    tester,
  ) async {
    await pumpHost(
      tester,
      const TransactionKeypadScaffold(
        keypadVisible: false,
        keypad: SizedBox.shrink(),
        child: SizedBox(
          key: Key("sheet_content"),
          width: double.infinity,
          height: 160,
        ),
      ),
    );

    expect(tester.getSize(find.byType(BottomSheet)).height, lessThan(260));
    expect(find.byKey(const Key("sheet_content")), findsOneWidget);
  });

  testWidgets(
    "transaction sheet keeps room for keypad when keypad is visible",
    (tester) async {
      await pumpHost(
        tester,
        const TransactionKeypadScaffold(
          keypadVisible: true,
          keypad: SizedBox(height: kTransactionKeypadHeight),
          child: SizedBox(
            key: Key("sheet_content"),
            width: double.infinity,
            height: 160,
          ),
        ),
      );

      expect(tester.getSize(find.byType(BottomSheet)).height, greaterThan(560));
      expect(find.byKey(const Key("sheet_content")), findsOneWidget);
    },
  );
}
