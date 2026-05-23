import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_sheet_shell.dart";

void main() {
  testWidgets("uses compact layout when keypad is hidden", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: TransactionKeypadScaffold(
              keypadVisible: false,
              keypad: const _ProbeKeypad(label: "keypad"),
              child: const _ProbeContent(label: "form"),
            ),
          ),
        ),
      ),
    );

    expect(_keypadOpacity(tester), 0);
    expect(_formSlotHeight(tester), isNull);
    expect(find.text("form"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("uses expanded layout when keypad is visible", (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: TransactionKeypadScaffold(
              keypadVisible: true,
              keypad: const _ProbeKeypad(label: "keypad"),
              child: const _ProbeContent(label: "form"),
            ),
          ),
        ),
      ),
    );

    expect(_keypadOpacity(tester), 1);
    expect(_formSlotHeight(tester), greaterThan(200));
    expect(find.text("keypad"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("hides keypad without layout overflow while fading", (tester) async {
    var keypadVisible = true;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return TransactionKeypadScaffold(
                  keypadVisible: keypadVisible,
                  keypad: const _ProbeKeypad(label: "keypad"),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _ProbeContent(label: "form"),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () =>
                              setState(() => keypadVisible = false),
                          child: const Text("hide keypad"),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text("hide keypad"));
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 75));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();

    expect(_keypadOpacity(tester), 0);
    expect(_formSlotHeight(tester), isNull);
  });
}

double _keypadOpacity(WidgetTester tester) {
  return tester
      .widget<AnimatedOpacity>(find.byKey(const Key("transaction_keypad_overlay")))
      .opacity;
}

double? _formSlotHeight(WidgetTester tester) {
  final slot = find.byKey(const Key("transaction_keypad_form_slot"));
  if (slot.evaluate().isEmpty) return null;
  return tester.widget<SizedBox>(slot).height;
}

class _ProbeContent extends StatelessWidget {
  const _ProbeContent({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(label);
  }
}

class _ProbeKeypad extends StatelessWidget {
  const _ProbeKeypad({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kTransactionKeypadHeight,
      child: Center(child: Text(label)),
    );
  }
}
