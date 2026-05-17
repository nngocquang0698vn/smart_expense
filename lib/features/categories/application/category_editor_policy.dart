import "../../../core/strings.dart";
import "../../../data/ledger_repository.dart";
import "../../../data/models/category_model.dart";

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.iconKey,
    required this.colorValue,
    required this.isIncome,
  });

  final String name;
  final String iconKey;
  final int colorValue;
  final bool isIncome;

  CategoryDraft copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    bool? isIncome,
  }) {
    return CategoryDraft(
      name: name ?? this.name,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isIncome: isIncome ?? this.isIncome,
    );
  }
}

class CategoryValidationResult {
  const CategoryValidationResult._({
    required this.draft,
    required this.message,
  });

  factory CategoryValidationResult.valid(CategoryDraft draft) {
    return CategoryValidationResult._(draft: draft, message: null);
  }

  factory CategoryValidationResult.invalid(String message) {
    return CategoryValidationResult._(
      draft: const CategoryDraft(
        name: "",
        iconKey: "category",
        colorValue: 0,
        isIncome: false,
      ),
      message: message,
    );
  }

  final CategoryDraft draft;
  final String? message;

  bool get isValid => message == null;
}

class CategoryDeleteDecision {
  const CategoryDeleteDecision._({required this.allowed, this.message});

  factory CategoryDeleteDecision.allow() {
    return const CategoryDeleteDecision._(allowed: true);
  }

  factory CategoryDeleteDecision.deny(String message) {
    return CategoryDeleteDecision._(allowed: false, message: message);
  }

  final bool allowed;
  final String? message;
}

class CategoryEditorPolicy {
  const CategoryEditorPolicy();

  CategoryDraft initialDraft({CategoryModel? existing}) {
    return CategoryDraft(
      name: existing?.name ?? "",
      iconKey: existing?.iconKey ?? "category",
      colorValue: existing?.colorValue ?? kCategoryColors.first,
      isIncome: existing?.isIncome ?? false,
    );
  }

  CategoryValidationResult validate(CategoryDraft draft) {
    final normalized = draft.copyWith(name: draft.name.trim());
    if (normalized.name.isEmpty) {
      return CategoryValidationResult.invalid(AppStrings.categoryNameRequired);
    }
    return CategoryValidationResult.valid(normalized);
  }

  CategoryDeleteDecision validateDelete(
    CategoryModel category, {
    required bool inUse,
  }) {
    if (isSystemCategory(category)) {
      return CategoryDeleteDecision.deny(AppStrings.categorySystemDeleteDenied);
    }
    if (inUse) {
      return CategoryDeleteDecision.deny(AppStrings.categoryInUseDeleteDenied);
    }
    return CategoryDeleteDecision.allow();
  }

  bool canEdit(CategoryModel category) => !isSystemCategory(category);

  bool isSystemCategory(CategoryModel category) =>
      isSystemCategoryId(category.id);

  bool isSystemCategoryId(String id) {
    return id == LedgerRepository.kOtherExpenseId ||
        id == LedgerRepository.kOtherIncomeId;
  }
}
