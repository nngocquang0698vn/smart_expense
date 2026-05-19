import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/core/utils/amount_input.dart";
import "package:smart_expense/core/utils/amount_input_notifier.dart";

void main() {
  late ProviderContainer container;

  tearDown(() {
    container.dispose();
  });

  test("build uses initial amount from family arg", () {
    container = ProviderContainer();
    expect(container.read(amountInputProvider(5000)), 5000);
  });

  test("appendDigit and backspace", () {
    container = ProviderContainer();
    container.listen(amountInputProvider(0), (_, _) {});
    final notifier = container.read(amountInputProvider(0).notifier);

    notifier.appendDigit(1);
    notifier.appendDigit(2);
    notifier.appendDigit(3);
    expect(container.read(amountInputProvider(0)), 123);
    expect(notifier.displayText, "123");

    notifier.backspace();
    expect(container.read(amountInputProvider(0)), 12);
  });

  test("appendTripleZero multiplies by 1000", () {
    container = ProviderContainer();
    container.listen(amountInputProvider(5), (_, _) {});
    final notifier = container.read(amountInputProvider(5).notifier);

    notifier.appendTripleZero();
    expect(container.read(amountInputProvider(5)), 5000);
  });

  test("appendTripleZero on zero does nothing", () {
    container = ProviderContainer();
    final notifier = container.read(amountInputProvider(0).notifier);

    notifier.appendTripleZero();
    expect(container.read(amountInputProvider(0)), 0);
  });

  test("setValue clamps to max", () {
    container = ProviderContainer();
    container.listen(amountInputProvider(0), (_, _) {});
    final notifier = container.read(amountInputProvider(0).notifier);

    notifier.setValue(kMaxAmountVnd + 1);
    expect(container.read(amountInputProvider(0)), kMaxAmountVnd);
  });
}
