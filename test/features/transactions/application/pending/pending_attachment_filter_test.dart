import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/seed/seed_attachments.dart";
import "package:smart_expense/features/transactions/application/pending/pending_attachment_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

LedgerTransaction _pending({
  required String id,
  bool audio = false,
  bool image = false,
}) {
  return LedgerTransaction(
    id: id,
    title: id,
    amountVnd: 1000,
    isIncome: false,
    categoryId: "cat",
    occurredAt: DateTime(2026, 5, 1),
    pending: true,
    complete: true,
    audio: audio ? SeedAttachments.voiceNote(fileSize: 1) : null,
    images: image
        ? [SeedAttachments.billImage(width: 1, height: 1, fileSize: 1)]
        : const [],
  );
}

void main() {
  final items = [
    _pending(id: "audio", audio: true),
    _pending(id: "image", image: true),
    _pending(id: "both", audio: true, image: true),
    _pending(id: "none"),
  ];

  group("filterPendingByAttachment", () {
    test("withAudio only returns audio transactions", () {
      final filtered = filterPendingByAttachment(
        items,
        PendingAttachmentFilter.withAudio,
      );
      expect(filtered.map((t) => t.id), ["audio", "both"]);
    });

    test("withImages only returns image transactions", () {
      final filtered = filterPendingByAttachment(
        items,
        PendingAttachmentFilter.withImages,
      );
      expect(filtered.map((t) => t.id), ["image", "both"]);
    });

    test("withoutAttachments excludes media", () {
      final filtered = filterPendingByAttachment(
        items,
        PendingAttachmentFilter.withoutAttachments,
      );
      expect(filtered.map((t) => t.id), ["none"]);
    });

    test("withMedia returns any attachment", () {
      final filtered = filterPendingByAttachment(
        items,
        PendingAttachmentFilter.withMedia,
      );
      expect(filtered.length, 3);
    });
  });
}
