import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/reports/application/category_report_transactions_provider.dart";
import "package:smart_expense/features/reports/application/report_category_detail_args.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";

import "package:smart_expense/core/testing/fake_ledger_repository.dart";

void main() {
  test("loads transactions filtered by category and period", () async {
    final repo = await createFakeLedgerRepository();
    final cats = await repo.categories();
    final expenseCat = cats.firstWhere((c) => !c.isIncome);
    await repo.addQuick(
      title: "Cafe",
      amountVnd: 45_000,
      isIncome: false,
      categoryId: expenseCat.id,
    );

    final container = ProviderContainer(
      overrides: [ledgerRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final args = ReportCategoryDetailArgs(
      category: expenseCat,
      isIncomeSide: false,
      period: AnalyticsPeriod.month,
      totalAmountVnd: 45_000,
    );

    final data = await container.read(
      categoryReportDetailProvider(args).future,
    );

    expect(data.transactions, isNotEmpty);
    expect(
      data.transactions.every((t) => t.categoryId == expenseCat.id),
      isTrue,
    );
    expect(data.categoriesById[expenseCat.id]?.name, expenseCat.name);
  });
}
