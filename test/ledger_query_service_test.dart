import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/services/ledger_query_service.dart";
import "package:smart_expense/shared/core/date_range.dart";

void main() {
  const service = LedgerQueryService();
  final range = AppDateRange(
    start: DateTime(2026, 5),
    end: DateTime(2026, 5, 31, 23, 59, 59),
  );

  LedgerTransaction tx({
    required String id,
    required int amount,
    required DateTime at,
    bool income = false,
    bool pending = false,
    String categoryId = "food",
  }) {
    return LedgerTransaction(
      id: id,
      title: id,
      amountVnd: amount,
      isIncome: income,
      categoryId: categoryId,
      occurredAt: at,
      pending: pending,
      complete: !pending,
    );
  }

  test("confirmedTotals excludes pending and out-of-range transactions", () {
    final totals = service.confirmedTotals([
      tx(
        id: "salary",
        amount: 10000000,
        income: true,
        at: DateTime(2026, 5, 1),
      ),
      tx(id: "lunch", amount: 80000, at: DateTime(2026, 5, 2)),
      tx(
        id: "pending",
        amount: 120000,
        pending: true,
        at: DateTime(2026, 5, 3),
      ),
      tx(id: "old", amount: 50000, at: DateTime(2026, 4, 30)),
    ], range);

    expect(totals.income, 10000000);
    expect(totals.expense, 80000);
    expect(totals.balance, 9920000);
  });

  test("pendingInRange sorts newest first and supports limit", () {
    final pending = service.pendingInRange(
      [
        tx(id: "old", amount: 1, pending: true, at: DateTime(2026, 5, 1)),
        tx(id: "new", amount: 1, pending: true, at: DateTime(2026, 5, 3)),
        tx(id: "confirmed", amount: 1, at: DateTime(2026, 5, 4)),
      ],
      range,
      limit: 1,
    );

    expect(pending.map((item) => item.id), ["new"]);
  });

  test("confirmedHistoryPage paginates confirmed transactions only", () {
    final page = service.confirmedHistoryPage(
      [
        tx(id: "1", amount: 1, at: DateTime(2026, 5, 1)),
        tx(id: "2", amount: 1, at: DateTime(2026, 5, 2), pending: true),
        tx(id: "3", amount: 1, at: DateTime(2026, 5, 3)),
        tx(id: "4", amount: 1, at: DateTime(2026, 5, 4)),
      ],
      range,
      offset: 1,
      limit: 2,
    );

    expect(page.map((item) => item.id), ["3", "1"]);
  });

  test("categoryBreakdown separates income and expense sides", () {
    final transactions = [
      tx(
        id: "coffee",
        amount: 30000,
        at: DateTime(2026, 5, 1),
        categoryId: "food",
      ),
      tx(
        id: "lunch",
        amount: 70000,
        at: DateTime(2026, 5, 1),
        categoryId: "food",
      ),
      tx(
        id: "salary",
        amount: 10000000,
        income: true,
        at: DateTime(2026, 5, 1),
        categoryId: "salary",
      ),
    ];

    expect(service.categoryBreakdown(transactions, range, incomeSide: false), {
      "food": 100000,
    });
    expect(service.categoryBreakdown(transactions, range, incomeSide: true), {
      "salary": 10000000,
    });
  });
}
