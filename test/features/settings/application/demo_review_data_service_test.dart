import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/testing/fake_ledger_repository.dart";
import "package:smart_expense/features/settings/application/demo_review_data_service.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "demo seed creates pending review transactions only when pending=true",
    () async {
      final repo = await createFakeLedgerRepository();
      await DemoReviewDataService(repo).seedPendingReviewTransactions();

      final pending = await repo.pendingAll(
        const DateFilterSelection(preset: DateFilterPreset.allTime),
      );
      final all = await repo.allTransactions();
      final notPendingWithMedia = all.firstWhere(
        (transaction) => transaction.title.contains("Không pending có media"),
      );

      expect(pending.length, 3);
      expect(pending.every((transaction) => transaction.pending), isTrue);
      expect(pending.any((transaction) => transaction.note != null), isTrue);
      expect(pending.any((transaction) => transaction.hasImages), isTrue);
      expect(pending.any((transaction) => transaction.hasAudio), isTrue);
      expect(notPendingWithMedia.pending, isFalse);
      expect(
        notPendingWithMedia.hasAudio || notPendingWithMedia.hasImages,
        isTrue,
      );
      expect(
        pending.any((transaction) => transaction.id == notPendingWithMedia.id),
        isFalse,
      );
    },
  );
}
