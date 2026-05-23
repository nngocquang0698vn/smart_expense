import "package:flutter/material.dart";

import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/presentation/transaction_editor_body.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_sheet_shell.dart";

Future<void> showTransactionEditor(
  BuildContext context,
  LedgerRepository repo, {
  LedgerTransaction? existing,
  bool defaultPending = false,
}) {
  return showTransactionFormSheet(
    context,
    child: TransactionEditorBody(
      repo: repo,
      existing: existing,
      defaultPending: defaultPending,
    ),
  );
}
