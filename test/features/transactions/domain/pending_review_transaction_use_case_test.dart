import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/services/pending_review_transaction_use_case.dart";

void main() {
  const useCase = PendingReviewTransactionUseCase();

  LedgerTransaction tx({
    required String id,
    required bool pending,
    String? note,
    AudioAttachmentModel? audio,
    List<ImageAttachmentModel> images = const [],
    DateTime? reviewedAt,
    DateTime? dismissedReviewAt,
  }) {
    return LedgerTransaction(
      id: id,
      title: id,
      amountVnd: 1,
      isIncome: false,
      categoryId: "food",
      occurredAt: DateTime(2026, 5, 24),
      pending: pending,
      complete: !pending,
      note: note,
      audio: audio,
      images: images,
      reviewedAt: reviewedAt,
      dismissedReviewAt: dismissedReviewAt,
    );
  }

  final audio = AudioAttachmentModel(
    id: "audio",
    durationMs: 1000,
    createdAt: DateTime(2026, 5, 24),
    mimeType: "audio/mpeg",
    extension: ".mp3",
    fileSize: 1,
  );
  final image = ImageAttachmentModel(
    id: "image",
    mimeType: "image/jpeg",
    extension: ".jpg",
    fileSize: 1,
    width: 1,
    height: 1,
    createdAt: DateTime(2026, 5, 24),
  );

  test("only pending=true transactions are eligible for review", () {
    expect(
      useCase.isPendingReviewTransaction(tx(id: "a", pending: true)),
      true,
    );
    expect(
      useCase.isPendingReviewTransaction(
        tx(id: "b", pending: true, audio: audio),
      ),
      true,
    );
    expect(
      useCase.isPendingReviewTransaction(
        tx(id: "c", pending: false, audio: audio),
      ),
      false,
    );
    expect(
      useCase.isPendingReviewTransaction(
        tx(id: "d", pending: false, note: "note", images: [image]),
      ),
      false,
    );
  });

  test("reviewed or dismissed transactions are no longer eligible", () {
    expect(
      useCase.isPendingReviewTransaction(
        tx(id: "reviewed", pending: true, reviewedAt: DateTime(2026, 5, 24)),
      ),
      false,
    );
    expect(
      useCase.isPendingReviewTransaction(
        tx(
          id: "dismissed",
          pending: true,
          dismissedReviewAt: DateTime(2026, 5, 24),
        ),
      ),
      false,
    );
  });
}
