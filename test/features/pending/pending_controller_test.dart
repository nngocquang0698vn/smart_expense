import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/data/date_filter.dart";
import "package:smart_expense/features/pending/application/pending_controller.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

import "../../fakes/fake_ledger_repository.dart";

void main() {
  late LedgerRepository repo;
  late PendingController controller;

  setUp(() async {
    repo = await createFakeLedgerRepository();
    controller = PendingController(repo);
  });

  tearDown(() {
    controller.dispose();
  });

  test("load returns pending transactions", () async {
    final cats = await repo.categories();
    final expenseCat = cats.firstWhere((c) => !c.isIncome);
    await repo.addQuick(
      title: "Pending tx",
      amountVnd: 10_000,
      isIncome: false,
      categoryId: expenseCat.id,
      pending: true,
    );

    await controller.load();

    expect(controller.viewModel.loading, isFalse);
    expect(controller.viewModel.transactions, isNotEmpty);
    expect(controller.viewModel.transactions.first.pending, isTrue);
  });

  test("updateFilter applies selection", () async {
    await controller.load();
    await controller.updateFilter(
      const DateFilterSelection(preset: DateFilterPreset.allTime),
    );

    expect(controller.filter.preset, DateFilterPreset.allTime);
    expect(controller.viewModel.loading, isFalse);
  });
}
