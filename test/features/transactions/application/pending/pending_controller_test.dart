import "package:flutter_test/flutter_test.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/application/pending/pending_attachment_filter.dart";
import "package:smart_expense/features/transactions/application/pending/pending_controller.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
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

  test("setAttachmentFilter filters and reconciles selection", () async {
    final cats = await repo.categories();
    final expenseCat = cats.firstWhere((c) => !c.isIncome);
    await repo.addQuick(
      title: "No media",
      amountVnd: 1,
      isIncome: false,
      categoryId: expenseCat.id,
      pending: true,
    );
    await repo.addQuick(
      title: "With image",
      amountVnd: 2,
      isIncome: false,
      categoryId: expenseCat.id,
      pending: true,
      images: [
        ImageAttachmentModel(
          id: "img-1",
          path: "x",
          mimeType: "image/jpeg",
          extension: ".jpg",
          fileSize: 1,
          width: 1,
          height: 1,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
    );

    await container.read(pendingControllerProvider.future);
    await container.read(pendingControllerProvider.notifier).reload();
    final notifier = container.read(pendingControllerProvider.notifier);
    final before = container.read(pendingControllerProvider).value!;
    final withImageId = before.viewModel.transactions
        .firstWhere((t) => t.hasImages)
        .id;
    notifier.selectTransaction(
      before.viewModel.transactions.firstWhere((t) => !t.hasImages).id,
    );
    notifier.setAttachmentFilter(PendingAttachmentFilter.withImages);

    final state = container.read(pendingControllerProvider).value!;
    expect(state.filteredTransactions.every((t) => t.hasImages), isTrue);
    expect(state.selectedTransactionId, withImageId);
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
