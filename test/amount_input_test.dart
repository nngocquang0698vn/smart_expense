import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/amount_input.dart";
import "package:smart_expense/core/money_format.dart";

void main() {
  group("formatMoneyDigits", () {
    test("formats with comma grouping", () {
      expect(formatMoneyDigits(0), "0");
      expect(formatMoneyDigits(1000), "1,000");
      expect(formatMoneyDigits(1250000), "1,250,000");
      expect(formatMoneyDigits(1000000000), "1,000,000,000");
    });
  });

  group("formatMoneyVi", () {
    test("appends VND symbol", () {
      expect(formatMoneyVi(1250000), "1,250,000 ₫");
    });
  });

  group("formatAmountInput", () {
    test("matches formatMoneyDigits", () {
      expect(formatAmountInput(1000), formatMoneyDigits(1000));
    });
  });

  group("AmountInputController", () {
    test("appendDigit and backspace", () {
      final c = AmountInputController();
      c.appendDigit(1);
      c.appendDigit(2);
      c.appendDigit(3);
      expect(c.value, 123);
      expect(c.displayText, "123");
      c.backspace();
      expect(c.value, 12);
    });

    test("appendTripleZero multiplies by 1000", () {
      final c = AmountInputController()..setValue(5);
      c.appendTripleZero();
      expect(c.value, 5000);
    });

    test("appendTripleZero on zero does nothing", () {
      final c = AmountInputController();
      c.appendTripleZero();
      expect(c.value, 0);
    });
  });

  group("parseAmountDigits", () {
    test("strips non-digits", () {
      expect(parseAmountDigits("1,234,567"), 1234567);
      expect(parseAmountDigits("1.234.567"), 1234567);
    });
  });
}
