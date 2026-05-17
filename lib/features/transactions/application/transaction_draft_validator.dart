enum TransactionDraftValidationError { amountRequired, categoryRequired }

class TransactionDraft {
  const TransactionDraft({
    required this.amountVnd,
    required this.pending,
    required this.categoryId,
  });

  final int amountVnd;
  final bool pending;
  final String? categoryId;
}

class TransactionDraftValidator {
  const TransactionDraftValidator();

  List<TransactionDraftValidationError> validate(TransactionDraft draft) {
    if (draft.pending) return const [];

    return [
      if (draft.amountVnd <= 0) TransactionDraftValidationError.amountRequired,
      if (draft.categoryId == null || draft.categoryId!.isEmpty)
        TransactionDraftValidationError.categoryRequired,
    ];
  }

  bool isComplete(TransactionDraft draft) {
    return draft.amountVnd > 0 &&
        draft.categoryId != null &&
        draft.categoryId!.isNotEmpty;
  }
}
