import "package:smart_expense/features/transactions/data/models/transaction_model.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

extension TransactionModelMapper on TransactionModel {
  LedgerTransaction toEntity() {
    return LedgerTransaction(
      id: id,
      title: title,
      amountVnd: amountVnd,
      isIncome: isIncome,
      categoryId: categoryId,
      occurredAt: occurredAt,
      pending: pending,
      complete: complete,
      note: note,
      audio: audio,
      images: images,
      reviewReason: reviewReason,
      reviewedAt: reviewedAt,
      dismissedReviewAt: dismissedReviewAt,
    );
  }
}

extension LedgerTransactionModelMapper on LedgerTransaction {
  TransactionModel toModel() {
    return TransactionModel(
      id: id,
      title: title,
      amountVnd: amountVnd,
      isIncome: isIncome,
      categoryId: categoryId,
      occurredAt: occurredAt,
      pending: pending,
      complete: complete,
      note: note,
      audio: audio,
      images: images,
      reviewReason: reviewReason,
      reviewedAt: reviewedAt,
      dismissedReviewAt: dismissedReviewAt,
    );
  }
}
