import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/data/models/category_model.dart";

enum CategoryValidationError { nameRequired }

enum CategoryDeleteBlockReason { systemCategory, inUse }

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
  const CategoryValidationResult._({required this.draft, required this.error});

  factory CategoryValidationResult.valid(CategoryDraft draft) {
    return CategoryValidationResult._(draft: draft, error: null);
  }

  factory CategoryValidationResult.invalid(CategoryValidationError error) {
    return CategoryValidationResult._(
      draft: const CategoryDraft(
        name: "",
        iconKey: "category",
        colorValue: 0,
        isIncome: false,
      ),
      error: error,
    );
  }

  final CategoryDraft draft;
  final CategoryValidationError? error;

  bool get isValid => error == null;
}

class CategoryDeleteDecision {
  const CategoryDeleteDecision._({required this.allowed, this.reason});

  factory CategoryDeleteDecision.allow() {
    return const CategoryDeleteDecision._(allowed: true);
  }

  factory CategoryDeleteDecision.deny(CategoryDeleteBlockReason reason) {
    return CategoryDeleteDecision._(allowed: false, reason: reason);
  }

  final bool allowed;
  final CategoryDeleteBlockReason? reason;
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
      return CategoryValidationResult.invalid(
        CategoryValidationError.nameRequired,
      );
    }
    return CategoryValidationResult.valid(normalized);
  }

  CategoryDeleteDecision validateDelete(
    CategoryModel category, {
    required bool inUse,
  }) {
    if (isSystemCategory(category)) {
      return CategoryDeleteDecision.deny(
        CategoryDeleteBlockReason.systemCategory,
      );
    }
    if (inUse) {
      return CategoryDeleteDecision.deny(CategoryDeleteBlockReason.inUse);
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
