import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/data/date_filter.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

import "package:smart_expense/core/testing/fake_ledger_repository.dart";

void main() {
  late LedgerRepository repo;

  setUp(() async {
    repo = await createFakeLedgerRepository();
  });

  test("ensureDefaults creates Khác categories and meta", () async {
    final categories = await repo.categories();
    expect(
      categories.any((c) => c.id == LedgerRepository.kOtherExpenseId),
      isTrue,
    );

    final meta = await repo.getMeta();
    expect(meta.containsKey("onboarded"), isTrue);
  });

  test("addQuick and confirmPending update pending lists", () async {
    final cats = await repo.categories();
    final expenseCat = cats.firstWhere((c) => !c.isIncome);

    await repo.addQuick(
      title: "Test pending",
      amountVnd: 50_000,
      isIncome: false,
      categoryId: expenseCat.id,
      pending: true,
    );

    final filter = const DateFilterSelection(preset: DateFilterPreset.allTime);
    final pending = await repo.pendingAll(filter);
    expect(pending, isNotEmpty);

    await repo.confirmPending(pending.first.id);
    final after = await repo.pendingAll(filter);
    expect(after.any((t) => t.id == pending.first.id), isFalse);
  });

  test("homeSummary separates income and expense", () async {
    final cats = await repo.categories();
    final expenseCat = cats.firstWhere((c) => !c.isIncome);
    final incomeCat = cats.firstWhere((c) => c.isIncome);

    await repo.addQuick(
      title: "Expense",
      amountVnd: 100_000,
      isIncome: false,
      categoryId: expenseCat.id,
    );
    await repo.addQuick(
      title: "Income",
      amountVnd: 200_000,
      isIncome: true,
      categoryId: incomeCat.id,
    );

    final filter = const DateFilterSelection(preset: DateFilterPreset.allTime);
    final summary = await repo.homeSummary(filter);
    expect(summary["expense"], greaterThan(0));
    expect(summary["income"], greaterThan(0));
  });
}
