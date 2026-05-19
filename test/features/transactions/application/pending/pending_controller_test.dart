import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/application/pending/pending_controller.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

import "package:smart_expense/core/testing/fake_ledger_repository.dart";

void main() {
  late LedgerRepository repo;
  late ProviderContainer container;
  late ProviderSubscription<AsyncValue<PendingState>> subscription;

  setUp(() async {
    repo = await createFakeLedgerRepository();
    container = ProviderContainer(
      overrides: [ledgerRepositoryProvider.overrideWithValue(repo)],
    );
    subscription = container.listen(pendingControllerProvider, (_, _) {});
  });

  tearDown(() {
    subscription.close();
    container.dispose();
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

    await container.read(pendingControllerProvider.future);
    await container.read(pendingControllerProvider.notifier).reload();
    final state = container.read(pendingControllerProvider).value!;

    expect(state.viewModel.loading, isFalse);
    expect(state.viewModel.transactions, isNotEmpty);
    expect(state.viewModel.transactions.first.pending, isTrue);
  });

  test("updateFilter applies selection", () async {
    await container.read(pendingControllerProvider.future);
    await container
        .read(pendingControllerProvider.notifier)
        .updateFilter(
          const DateFilterSelection(preset: DateFilterPreset.allTime),
        );
    final state = container.read(pendingControllerProvider).value!;

    expect(state.filter.preset, DateFilterPreset.allTime);
    expect(state.viewModel.loading, isFalse);
  });
}
