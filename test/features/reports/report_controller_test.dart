import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/data/date_filter.dart";
import "package:smart_expense/features/reports/application/report_controller.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

import "../../fakes/fake_ledger_repository.dart";

void main() {
  late LedgerRepository repo;
  late ReportController controller;

  setUp(() async {
    repo = await createFakeLedgerRepository();
    controller = ReportController(repo);
  });

  tearDown(() {
    controller.dispose();
  });

  test("load builds report view model from repo totals", () async {
    final cats = await repo.categories();
    final expenseCat = cats.firstWhere((c) => !c.isIncome);
    await repo.addQuick(
      title: "Lunch",
      amountVnd: 80_000,
      isIncome: false,
      categoryId: expenseCat.id,
    );

    await controller.load();

    expect(controller.loading, isFalse);
    expect(controller.viewModel.expense, greaterThan(0));
  });

  test("selectPeriod updates period and reloads", () async {
    await controller.load();
    await controller.selectPeriod(AnalyticsPeriod.year);

    expect(controller.period, AnalyticsPeriod.year);
    expect(controller.loading, isFalse);
  });
}
