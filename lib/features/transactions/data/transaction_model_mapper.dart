import "../../../data/models/transaction_model.dart";
import "../domain/entities/ledger_transaction.dart";

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
    );
  }
}
