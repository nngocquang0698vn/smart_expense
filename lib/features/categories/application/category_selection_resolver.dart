import "package:smart_expense/features/transactions/data/models/category_model.dart";

class CategorySelectionResolver {
  const CategorySelectionResolver();

  List<CategoryModel> enabledForSide(
    List<CategoryModel> categories, {
    required bool isIncome,
  }) {
    final seen = <String>{};
    return [
      for (final category in categories)
        if (category.enabled &&
            category.isIncome == isIncome &&
            seen.add(category.id))
          category,
    ];
  }

  String? selectedValueOrNull({
    required String? selectedId,
    required List<CategoryModel> items,
  }) {
    if (selectedId == null || selectedId.isEmpty) return null;
    return items.any((category) => category.id == selectedId)
        ? selectedId
        : null;
  }

  String? fallbackId(List<CategoryModel> items) {
    return items.isEmpty ? null : items.first.id;
  }

  String? selectedOrFallback({
    required String? selectedId,
    required List<CategoryModel> items,
  }) {
    return selectedValueOrNull(selectedId: selectedId, items: items) ??
        fallbackId(items);
  }
}

class CategoryNameLookup {
  CategoryNameLookup(List<CategoryModel> categories) : _categories = categories;

  final List<CategoryModel> _categories;

  String? idFor({
    required String name,
    required bool isIncome,
    String? fallbackName,
  }) {
    final normalizedName = name.trim();
    for (final category in _categories) {
      if (category.enabled &&
          category.isIncome == isIncome &&
          category.name == normalizedName) {
        return category.id;
      }
    }

    final normalizedFallback = fallbackName?.trim();
    if (normalizedFallback != null && normalizedFallback.isNotEmpty) {
      for (final category in _categories) {
        if (category.enabled &&
            category.isIncome == isIncome &&
            category.name == normalizedFallback) {
          return category.id;
        }
      }
    }

    for (final category in _categories) {
      if (category.enabled && category.isIncome == isIncome) {
        return category.id;
      }
    }
    return null;
  }
}
