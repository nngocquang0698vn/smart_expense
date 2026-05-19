import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/categories/application/category_editor_policy.dart";

class CategoriesViewModel {
  CategoriesViewModel._({
    required this.expense,
    required this.income,
    CategoryEditorPolicy policy = const CategoryEditorPolicy(),
  }) : _policy = policy;

  factory CategoriesViewModel.empty() {
    return CategoriesViewModel._(expense: const [], income: const []);
  }

  factory CategoriesViewModel.fromCategories(List<LedgerCategory> categories) {
    return CategoriesViewModel._(
      expense: [
        for (final category in categories)
          if (!category.isIncome) category,
      ],
      income: [
        for (final category in categories)
          if (category.isIncome) category,
      ],
    );
  }

  final List<LedgerCategory> expense;
  final List<LedgerCategory> income;
  final CategoryEditorPolicy _policy;

  bool get isEmpty => expense.isEmpty && income.isEmpty;

  bool isSystem(LedgerCategory category) => _policy.isSystemCategory(category);
}
