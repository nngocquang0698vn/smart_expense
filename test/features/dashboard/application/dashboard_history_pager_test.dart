import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/data/models/transaction_model.dart";
import "package:smart_expense/features/dashboard/application/dashboard_view_model.dart";

void main() {
  const pager = DashboardHistoryPager();

  TransactionModel tx(String id) {
    return TransactionModel(
      id: id,
      title: id,
      amountVnd: 1000,
      isIncome: false,
      categoryId: "food",
      occurredAt: DateTime(2026, 5, 1),
      pending: false,
      complete: true,
    );
  }

  test("reset clears loaded history and keeps pagination open", () {
    final viewModel = const DashboardViewModel.initial().copyWith(
      history: [tx("1")],
      historyOffset: 1,
      allLoaded: true,
    );

    final next = pager.reset(viewModel);

    expect(next.history, isEmpty);
    expect(next.historyOffset, 0);
    expect(next.allLoaded, isFalse);
  });

  test(
    "appendBatch advances offset and keeps loading open for a full page",
    () {
      final next = pager.appendBatch(const DashboardViewModel.initial(), [
        tx("1"),
        tx("2"),
      ], pageSize: 2);

      expect(next.history.map((item) => item.id), ["1", "2"]);
      expect(next.historyOffset, 2);
      expect(next.loadingMore, isFalse);
      expect(next.allLoaded, isFalse);
    },
  );

  test("appendBatch marks allLoaded when returned page is short", () {
    final next = pager.appendBatch(const DashboardViewModel.initial(), [
      tx("1"),
    ], pageSize: 2);

    expect(next.historyOffset, 1);
    expect(next.allLoaded, isTrue);
  });

  test("appendBatch marks allLoaded when returned page is empty", () {
    final next = pager.appendBatch(
      const DashboardViewModel.initial().copyWith(loadingMore: true),
      const [],
      pageSize: 2,
    );

    expect(next.history, isEmpty);
    expect(next.historyOffset, 0);
    expect(next.loadingMore, isFalse);
    expect(next.allLoaded, isTrue);
  });
}
