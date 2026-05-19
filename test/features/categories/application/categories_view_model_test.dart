import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/categories/application/categories_view_model.dart";

void main() {
  LedgerCategory category({
    required String id,
    required String name,
    required bool isIncome,
    bool enabled = true,
  }) {
    return LedgerCategory(
      id: id,
      name: name,
      iconKey: "category",
      colorValue: 0xFF26A69A,
      isIncome: isIncome,
      enabled: enabled,
    );
  }

  test("splits categories into expense and income sections", () {
    final viewModel = CategoriesViewModel.fromCategories([
      category(id: "salary", name: "Lương", isIncome: true),
      category(id: "food", name: "Ăn uống", isIncome: false),
      category(id: "bonus", name: "Thưởng", isIncome: true),
    ]);

    expect(viewModel.expense.map((c) => c.id), ["food"]);
    expect(viewModel.income.map((c) => c.id), ["salary", "bonus"]);
  });

  test("identifies fixed fallback categories as system categories", () {
    final viewModel = CategoriesViewModel.fromCategories([
      category(
        id: LedgerRepository.kOtherExpenseId,
        name: "Khác",
        isIncome: false,
      ),
      category(id: "food", name: "Ăn uống", isIncome: false),
    ]);

    expect(viewModel.isSystem(viewModel.expense.first), isTrue);
    expect(viewModel.isSystem(viewModel.expense.last), isFalse);
  });
}
