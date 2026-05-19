import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/reports/application/report_controller.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

import "package:smart_expense/core/testing/fake_ledger_repository.dart";

void main() {
  late LedgerRepository repo;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<ReportState>> subscription;

  setUp(() async {
    repo = await createFakeLedgerRepository();
    container = ProviderContainer(
      overrides: [ledgerRepositoryProvider.overrideWithValue(repo)],
    );
    subscription = container.listen(reportControllerProvider, (_, _) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
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

    await container.read(reportControllerProvider.future);
    await container.read(reportControllerProvider.notifier).reload();
    final state = container.read(reportControllerProvider).value!;

    expect(state.loading, isFalse);
    expect(state.viewModel.expense, greaterThan(0));
  });

  test("selectPeriod updates period and reloads", () async {
    await container.read(reportControllerProvider.future);
    await container
        .read(reportControllerProvider.notifier)
        .selectPeriod(AnalyticsPeriod.year);
    final state = container.read(reportControllerProvider).value!;

    expect(state.period, AnalyticsPeriod.year);
    expect(state.loading, isFalse);
  });
}
