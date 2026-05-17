import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/data/date_filter.dart";
import "package:smart_expense/features/home/application/home_controller.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

import "../../fakes/fake_ledger_repository.dart";

void main() {
  late LedgerRepository repo;
  late HomeController controller;

  setUp(() async {
    repo = await createFakeLedgerRepository();
    controller = HomeController(repo);
  });

  tearDown(() {
    controller.dispose();
  });

  test("bootstrap loads summary and categories", () async {
    final cats = await repo.categories();
    final expenseCat = cats.firstWhere((c) => !c.isIncome);
    await repo.addQuick(
      title: "Coffee",
      amountVnd: 35_000,
      isIncome: false,
      categoryId: expenseCat.id,
    );

    await controller.bootstrap();

    expect(controller.viewModel.topLoading, isFalse);
    expect(controller.viewModel.summary.expense, greaterThan(0));
    expect(controller.viewModel.categories, isNotEmpty);
  });

  test("updateFilter reloads with new range", () async {
    await controller.bootstrap();
    await controller.updateFilter(
      const DateFilterSelection(preset: DateFilterPreset.allTime),
    );

    expect(controller.filter.preset, DateFilterPreset.allTime);
    expect(controller.viewModel.topLoading, isFalse);
  });
}
