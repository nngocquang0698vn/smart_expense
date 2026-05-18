import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/shared/components/app_date_picker_layout.dart";
import "package:smart_expense/shared/components/app_date_picker_support.dart";

void main() {
  testWidgets("wrapDatePickerDialog constrains on desktop width", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(1200, 800)),
          child: Builder(
            builder: (context) {
              return wrapDatePickerDialog(
                context,
                const SizedBox(key: Key("picker")),
              );
            },
          ),
        ),
      ),
    );

    final box = tester.widget<ConstrainedBox>(
      find.byKey(const Key("app_date_picker_dialog_constraint")),
    );
    expect(box.constraints.maxWidth, AppDatePickerLayout.dialogMaxWidth);
    expect(box.constraints.maxHeight, AppDatePickerLayout.dialogMaxHeight);
    expect(find.byKey(const Key("picker")), findsOneWidget);
  });

  testWidgets("wrapDatePickerDialog passes through on mobile width", (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Builder(
            builder: (context) {
              return wrapDatePickerDialog(
                context,
                const SizedBox(key: Key("picker")),
              );
            },
          ),
        ),
      ),
    );

    expect(
      find.byKey(const Key("app_date_picker_dialog_constraint")),
      findsNothing,
    );
    expect(find.byKey(const Key("picker")), findsOneWidget);
  });
}
