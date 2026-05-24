import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

import "package:smart_expense/core/testing/fake_ledger_repository.dart";

void main() {
  late LedgerRepository repo;

  setUp(() async {
    repo = await createFakeLedgerRepository();
  });

  test(
    "ensureDefaults creates simplified enabled categories and meta",
    () async {
      final categories = await repo.categories();
      expect(
        categories.any((c) => c.id == LedgerRepository.kOtherExpenseId),
        isTrue,
      );
      expect(
        categories.any((c) => c.id == LedgerRepository.kOtherIncomeId),
        isTrue,
      );
      expect(
        categories
            .firstWhere((c) => c.id == LedgerRepository.kDefaultExpenseFoodId)
            .name,
        "Ăn uống",
      );
      expect(
        categories
            .firstWhere(
              (c) => c.id == LedgerRepository.kDefaultExpenseShoppingId,
            )
            .name,
        "Mua sắm",
      );
      expect(
        categories
            .firstWhere(
              (c) => c.id == LedgerRepository.kDefaultExpenseTransportId,
            )
            .name,
        "Di chuyển",
      );
      expect(
        categories
            .firstWhere((c) => c.id == LedgerRepository.kDefaultExpenseBillsId)
            .name,
        "Hoá đơn",
      );
      expect(
        categories
            .firstWhere((c) => c.id == LedgerRepository.kDefaultIncomeSalaryId)
            .name,
        "Lương",
      );

      final enabledExpenseNames = categories
          .where((c) => c.enabled && !c.isIncome)
          .map((c) => c.name)
          .toSet();
      expect(
        enabledExpenseNames,
        equals({"Ăn uống", "Di chuyển", "Mua sắm", "Hoá đơn", "Khác"}),
      );

      final enabledIncomeNames = categories
          .where((c) => c.enabled && c.isIncome)
          .map((c) => c.name)
          .toSet();
      expect(enabledIncomeNames, equals({"Lương", "Khác"}));
      expect(categories.any((c) => c.name == "Thu nhập"), isFalse);

      expect(
        categories.where((c) => !c.enabled).map((c) => c.name).toSet(),
        containsAll({"Cà phê", "Tạp hoá", "Thu nhập khác"}),
      );

      final enabledExpenseList = categories
          .where((c) => c.enabled && !c.isIncome)
          .map((c) => c.name)
          .toList();
      final enabledIncomeList = categories
          .where((c) => c.enabled && c.isIncome)
          .map((c) => c.name)
          .toList();
      expect(enabledExpenseList.last, "Khác");
      expect(enabledIncomeList.last, "Khác");

      final meta = await repo.getMeta();
      expect(meta.containsKey("onboarded"), isTrue);
    },
  );

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
