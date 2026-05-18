import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/shared/components/app_empty_state.dart";

void main() {
  testWidgets("AppEmptyState shows message and optional action", (
    tester,
  ) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            message: "Chưa có giao dịch nào",
            action: FilledButton(
              onPressed: () => tapped = true,
              child: const Text("Thêm giao dịch"),
            ),
          ),
        ),
      ),
    );

    expect(find.text("Chưa có giao dịch nào"), findsOneWidget);
    await tester.tap(find.text("Thêm giao dịch"));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
