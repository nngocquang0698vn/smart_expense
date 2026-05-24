import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

class PendingReviewTransactionUseCase {
  const PendingReviewTransactionUseCase();

  bool isPendingReviewTransaction(LedgerTransaction transaction) {
    return transaction.pending &&
        transaction.reviewedAt == null &&
        transaction.dismissedReviewAt == null;
  }

  List<LedgerTransaction> filter(Iterable<LedgerTransaction> transactions) {
    return transactions.where(isPendingReviewTransaction).toList();
  }
}
