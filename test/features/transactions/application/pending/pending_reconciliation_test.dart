import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/application/pending/pending_attachment_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/transaction_image_limits.dart";

LedgerTransaction _tx({
  required String id,
  bool withImage = false,
  bool withAudio = false,
}) {
  return LedgerTransaction(
    id: id,
    title: "Test $id",
    amountVnd: 10_000,
    isIncome: false,
    categoryId: "c1",
    occurredAt: DateTime(2026, 5, 1),
    pending: true,
    complete: true,
    audio: withAudio
        ? AudioAttachmentModel(
            id: "a1",
            path: "p",
            mimeType: "audio/m4a",
            durationMs: 1000,
            createdAt: DateTime(2026, 5, 1),
            extension: ".m4a",
            fileSize: 100,
          )
        : null,
    images: withImage
        ? [
            ImageAttachmentModel(
              id: "i1",
              path: "p",
              mimeType: "image/jpeg",
              extension: ".jpg",
              fileSize: 100,
              width: 1,
              height: 1,
              createdAt: DateTime(2026, 5, 1),
            ),
          ]
        : const [],
  );
}

void main() {
  group("TransactionImageLimits", () {
    test("remainingSlots respects max 5", () {
      expect(TransactionImageLimits.remainingSlots(0), 5);
      expect(TransactionImageLimits.remainingSlots(5), 0);
      expect(TransactionImageLimits.canAddMore(4), isTrue);
      expect(TransactionImageLimits.canAddMore(5), isFalse);
    });
  });

  group("filterPendingByAttachment", () {
    final all = [
      _tx(id: "1"),
      _tx(id: "2", withImage: true),
      _tx(id: "3", withAudio: true),
      _tx(id: "4", withImage: true, withAudio: true),
    ];

    test("all returns every transaction", () {
      expect(
        filterPendingByAttachment(all, PendingAttachmentFilter.all).length,
        4,
      );
    });

    test("withImages filters correctly", () {
      final result = filterPendingByAttachment(
        all,
        PendingAttachmentFilter.withImages,
      );
      expect(result.map((t) => t.id), ["2", "4"]);
    });

    test("withAudio filters correctly", () {
      final result = filterPendingByAttachment(
        all,
        PendingAttachmentFilter.withAudio,
      );
      expect(result.map((t) => t.id), ["3", "4"]);
    });

    test("withMedia filters union", () {
      final result = filterPendingByAttachment(
        all,
        PendingAttachmentFilter.withMedia,
      );
      expect(result.map((t) => t.id), ["2", "3", "4"]);
    });

    test("withoutAttachments filters empty media", () {
      final result = filterPendingByAttachment(
        all,
        PendingAttachmentFilter.withoutAttachments,
      );
      expect(result.map((t) => t.id), ["1"]);
    });
  });

  group("selection helpers", () {
    final filtered = [_tx(id: "a"), _tx(id: "b"), _tx(id: "c")];

    test("nextPendingTransactionId advances", () {
      expect(nextPendingTransactionId(filtered: filtered, currentId: "a"), "b");
      expect(
        nextPendingTransactionId(filtered: filtered, currentId: "c"),
        isNull,
      );
      expect(
        nextPendingTransactionId(filtered: filtered, currentId: null),
        isNull,
      );
    });

    test("previousPendingTransactionId goes back", () {
      expect(
        previousPendingTransactionId(filtered: filtered, currentId: "b"),
        "a",
      );
      expect(
        previousPendingTransactionId(filtered: filtered, currentId: "a"),
        isNull,
      );
    });

    test("reconcilePendingSelection keeps valid id", () {
      expect(
        reconcilePendingSelection(filtered: filtered, selectedId: "b"),
        "b",
      );
    });

    test("reconcilePendingSelection picks first when invalid", () {
      expect(
        reconcilePendingSelection(filtered: filtered, selectedId: "z"),
        "a",
      );
    });
  });
}
