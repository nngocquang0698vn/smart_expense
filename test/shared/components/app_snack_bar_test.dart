import "package:awesome_snackbar_content/awesome_snackbar_content.dart";
import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/shared/components/app_snack_bar.dart";

void main() {
  testWidgets("showAppSnackBar renders awesome snackbar content", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppSnackBar(
                context,
                title: "Đã lưu",
                message: "Đã lưu giao dịch.",
                type: AppSnackBarType.success,
              ),
              child: const Text("Show"),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("Show"));
    await tester.pump();

    expect(find.byType(AwesomeSnackbarContent), findsOneWidget);
    expect(find.text("Đã lưu"), findsOneWidget);
    expect(find.text("Đã lưu giao dịch."), findsOneWidget);
  });
}
