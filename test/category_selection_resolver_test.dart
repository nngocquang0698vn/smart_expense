import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/data/models/category_model.dart";
import "package:smart_expense/features/categories/application/category_selection_resolver.dart";

void main() {
  const resolver = CategorySelectionResolver();

  CategoryModel category({
    required String id,
    required bool isIncome,
    bool enabled = true,
  }) {
    return CategoryModel(
      id: id,
      name: id,
      iconKey: "category",
      colorValue: 0xFF006B68,
      isIncome: isIncome,
      enabled: enabled,
    );
  }

  test("enabledForSide filters by enabled status and transaction side", () {
    final items = resolver.enabledForSide([
      category(id: "food", isIncome: false),
      category(id: "salary", isIncome: true),
      category(id: "hidden", isIncome: false, enabled: false),
    ], isIncome: false);

    expect(items.map((item) => item.id), ["food"]);
  });

  test("enabledForSide removes duplicate category ids", () {
    final items = resolver.enabledForSide([
      category(id: "system_khac_income", isIncome: true),
      category(id: "system_khac_income", isIncome: true),
    ], isIncome: true);

    expect(items, hasLength(1));
  });

  test("selectedValueOrNull returns null when selected id is not in items", () {
    final items = [category(id: "food", isIncome: false)];

    expect(
      resolver.selectedValueOrNull(
        selectedId: "system_khac_income",
        items: items,
      ),
      isNull,
    );
  });

  test("selectedOrFallback keeps valid selected id or returns first item", () {
    final items = [
      category(id: "food", isIncome: false),
      category(id: "coffee", isIncome: false),
    ];

    expect(
      resolver.selectedOrFallback(selectedId: "coffee", items: items),
      "coffee",
    );
    expect(
      resolver.selectedOrFallback(
        selectedId: "system_khac_income",
        items: items,
      ),
      "food",
    );
  });

  test("CategoryNameLookup resolves Khác to the matching side", () {
    CategoryModel khac(String id, bool isIncome) {
      return CategoryModel(
        id: id,
        name: "Khác",
        iconKey: "category",
        colorValue: 0xFF006B68,
        isIncome: isIncome,
      );
    }

    final lookup = CategoryNameLookup([
      khac("system_khac_expense", false),
      khac("system_khac_income", true),
    ]);

    expect(lookup.idFor(name: "Khác", isIncome: false), "system_khac_expense");
    expect(lookup.idFor(name: "Khác", isIncome: true), "system_khac_income");
  });

  test("CategoryNameLookup falls back within the same income side", () {
    final lookup = CategoryNameLookup([
      category(id: "food", isIncome: false),
      category(id: "salary", isIncome: true),
    ]);

    expect(lookup.idFor(name: "Missing", isIncome: false), "food");
    expect(lookup.idFor(name: "Missing", isIncome: true), "salary");
  });
}
