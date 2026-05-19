import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/utils/amount_input.dart";
import "package:smart_expense/core/utils/money_format.dart";

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

  group("parseAmountDigits", () {
    test("strips non-digits", () {
      expect(parseAmountDigits("1,234,567"), 1234567);
      expect(parseAmountDigits("1.234.567"), 1234567);
    });
  });
}
