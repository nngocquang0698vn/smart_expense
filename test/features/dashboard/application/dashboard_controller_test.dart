import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/dashboard/application/dashboard_controller.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

import "package:smart_expense/core/testing/fake_ledger_repository.dart";

void main() {
  late LedgerRepository repo;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<DashboardState>> subscription;

  setUp(() async {
    repo = await createFakeLedgerRepository();
    container = ProviderContainer(
      overrides: [ledgerRepositoryProvider.overrideWithValue(repo)],
    );
    subscription = container.listen(dashboardControllerProvider, (_, _) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
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

    await container.read(dashboardControllerProvider.future);
    await container.read(dashboardControllerProvider.notifier).refresh();
    final refreshed = container.read(dashboardControllerProvider).value!;

    expect(refreshed.viewModel.topLoading, isFalse);
    expect(refreshed.viewModel.summary.expense, greaterThan(0));
    expect(refreshed.viewModel.categories, isNotEmpty);
  });

  test("updateFilter reloads with new range", () async {
    await container.read(dashboardControllerProvider.future);
    await container
        .read(dashboardControllerProvider.notifier)
        .updateFilter(
          const DateFilterSelection(preset: DateFilterPreset.allTime),
        );
    final state = container.read(dashboardControllerProvider).value!;

    expect(state.filter.preset, DateFilterPreset.allTime);
    expect(state.viewModel.topLoading, isFalse);
  });
}
