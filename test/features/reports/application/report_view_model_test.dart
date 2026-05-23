import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";

void main() {
  const builder = ReportViewModelBuilder();

  LedgerCategory category(String id, String name) {
    return LedgerCategory(
      id: id,
      name: name,
      iconKey: "category",
      colorValue: 0xFF006B68,
      isIncome: false,
    );
  }

  test(
    "builds sorted positive report slices and ignores unknown categories",
    () {
      final viewModel = builder.build(
        totals: const {"income": 1000000, "expense": 250000},
        breakdown: const {
          "food": 50000,
          "coffee": 80000,
          "zero": 0,
          "unknown": 120000,
        },
        categories: [category("food", "Ăn uống"), category("coffee", "Cà phê")],
      );

      expect(viewModel.income, 1000000);
      expect(viewModel.expense, 250000);
      expect(viewModel.balance, 750000);
      expect(viewModel.sliceTotal, 130000);
      expect(viewModel.slices.map((slice) => slice.id), ["coffee", "food"]);
    },
  );

  test("slicePercent is 0 when slice total is 0", () {
    const empty = ReportViewModel.empty();
    expect(empty.slicePercent(100), 0);
  });

  test("slicePercent matches category share", () {
    final viewModel = builder.build(
      totals: const {"income": 0, "expense": 100},
      breakdown: const {"food": 40},
      categories: [category("food", "Ăn uống")],
    );
    expect(viewModel.slicePercent(40), 100);
  });
}
