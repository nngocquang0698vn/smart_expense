import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/features/reports/application/report_view_model.dart";

void main() {
  const builder = ReportViewModelBuilder();

  CategoryModel category(String id, String name) {
    return CategoryModel(
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
}
