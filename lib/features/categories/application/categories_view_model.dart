import "../../../data/models/category_model.dart";
import "category_editor_policy.dart";

class CategoriesViewModel {
  CategoriesViewModel._({
    required this.expense,
    required this.income,
    CategoryEditorPolicy policy = const CategoryEditorPolicy(),
  }) : _policy = policy;

  factory CategoriesViewModel.empty() {
    return CategoriesViewModel._(expense: const [], income: const []);
  }

  factory CategoriesViewModel.fromCategories(List<CategoryModel> categories) {
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

  final List<CategoryModel> expense;
  final List<CategoryModel> income;
  final CategoryEditorPolicy _policy;

  bool get isEmpty => expense.isEmpty && income.isEmpty;

  bool isSystem(CategoryModel category) => _policy.isSystemCategory(category);
}
