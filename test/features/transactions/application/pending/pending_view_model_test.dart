import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/application/pending/pending_view_model.dart";

void main() {
  LedgerCategory category(String id) {
    return LedgerCategory(
      id: id,
      name: id,
      iconKey: "category",
      colorValue: 0xFF006B68,
      isIncome: false,
    );
  }

  LedgerTransaction tx(String id) {
    return LedgerTransaction(
      id: id,
      title: id,
      amountVnd: 1000,
      isIncome: false,
      categoryId: "food",
      occurredAt: DateTime(2026, 5, 1),
      pending: true,
      complete: true,
    );
  }

  test("initial state is loading and empty", () {
    const viewModel = PendingViewModel.initial();

    expect(viewModel.loading, isTrue);
    expect(viewModel.isEmpty, isTrue);
    expect(viewModel.categoryMap, isEmpty);
  });

  test("categoryMap indexes categories by id", () {
    final viewModel = PendingViewModel(
      transactions: [tx("1")],
      categories: [category("food"), category("coffee")],
      loading: false,
    );

    expect(viewModel.isEmpty, isFalse);
    expect(viewModel.categoryMap.keys, containsAll(["food", "coffee"]));
  });
}
