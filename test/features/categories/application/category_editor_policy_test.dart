import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/categories/application/category_editor_policy.dart";

void main() {
  const policy = CategoryEditorPolicy();

  LedgerCategory category({
    String id = "food",
    String name = "Ăn uống",
    bool isIncome = false,
    bool enabled = true,
  }) {
    return LedgerCategory(
      id: id,
      name: name,
      iconKey: "restaurant",
      colorValue: 0xFF26A69A,
      isIncome: isIncome,
      enabled: enabled,
    );
  }

  test("creates a default expense draft for new categories", () {
    final draft = policy.initialDraft();

    expect(draft.name, isEmpty);
    expect(draft.iconKey, "category");
    expect(draft.colorValue, kCategoryColors.first);
    expect(draft.isIncome, isFalse);
  });

  test("creates an edit draft from an existing category", () {
    final draft = policy.initialDraft(
      existing: category(
        id: "salary",
        name: "Lương",
        isIncome: true,
        enabled: false,
      ).copyWith(iconKey: "payments", colorValue: 0xFF4CAF50),
    );

    expect(draft.name, "Lương");
    expect(draft.iconKey, "payments");
    expect(draft.colorValue, 0xFF4CAF50);
    expect(draft.isIncome, isTrue);
  });

  test("trims the category name before saving", () {
    final draft = const CategoryDraft(
      name: "  Cà phê  ",
      iconKey: "local_cafe",
      colorValue: 0xFF26A69A,
      isIncome: false,
    );

    final result = policy.validate(draft);

    expect(result.isValid, isTrue);
    expect(result.draft.name, "Cà phê");
    expect(result.error, isNull);
  });

  test("rejects empty category names", () {
    final result = policy.validate(
      const CategoryDraft(
        name: "   ",
        iconKey: "category",
        colorValue: 0xFF26A69A,
        isIncome: false,
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.error, CategoryValidationError.nameRequired);
  });

  test("does not allow deleting system categories", () {
    final result = policy.validateDelete(
      category(id: LedgerRepository.kOtherExpenseId, name: "Khác"),
      inUse: false,
    );

    expect(result.allowed, isFalse);
    expect(result.reason, CategoryDeleteBlockReason.systemCategory);
  });

  test("does not allow deleting categories that still have transactions", () {
    final result = policy.validateDelete(category(), inUse: true);

    expect(result.allowed, isFalse);
    expect(result.reason, CategoryDeleteBlockReason.inUse);
  });
}
