enum TransactionDraftValidationError {
  titleRequired,
  amountRequired,
  categoryRequired,
}

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

  /// First validation error suitable for snackbars, in priority order.
  static TransactionDraftValidationError? firstUserError(
    List<TransactionDraftValidationError> errors, {
    bool includeTitle = false,
  }) {
    if (includeTitle &&
        errors.contains(TransactionDraftValidationError.titleRequired)) {
      return TransactionDraftValidationError.titleRequired;
    }
    if (errors.contains(TransactionDraftValidationError.amountRequired)) {
      return TransactionDraftValidationError.amountRequired;
    }
    if (errors.contains(TransactionDraftValidationError.categoryRequired)) {
      return TransactionDraftValidationError.categoryRequired;
    }
    return null;
  }

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

class TransactionSaveDraft {
  const TransactionSaveDraft({
    required this.rawTitle,
    required this.amountVnd,
    required this.pending,
    required this.selectedCategoryId,
    required this.fallbackCategoryId,
    this.fallbackTitle,
    this.requireTitle = false,
  });

  final String rawTitle;
  final int amountVnd;
  final bool pending;
  final String? selectedCategoryId;
  final String? fallbackCategoryId;
  final String? fallbackTitle;
  final bool requireTitle;
}

class TransactionSaveDraftResult {
  const TransactionSaveDraftResult({
    required this.title,
    required this.categoryId,
    required this.complete,
    required this.errors,
  });

  final String title;
  final String? categoryId;
  final bool complete;
  final List<TransactionDraftValidationError> errors;

  bool get isValid => errors.isEmpty;
}

class TransactionDraftResolver {
  const TransactionDraftResolver({
    TransactionDraftValidator validator = const TransactionDraftValidator(),
  }) : _validator = validator;

  final TransactionDraftValidator _validator;

  TransactionSaveDraftResult resolve(TransactionSaveDraft draft) {
    final title = draft.rawTitle.trim().isNotEmpty
        ? draft.rawTitle.trim()
        : (draft.fallbackTitle ?? "").trim();
    final categoryId = _normalizeCategoryId(
      draft.selectedCategoryId ?? draft.fallbackCategoryId,
    );
    final transactionDraft = TransactionDraft(
      amountVnd: draft.amountVnd,
      pending: draft.pending,
      categoryId: categoryId,
    );
    final errors = <TransactionDraftValidationError>[
      if (draft.requireTitle && title.isEmpty)
        TransactionDraftValidationError.titleRequired,
      ..._validator.validate(transactionDraft),
    ];

    return TransactionSaveDraftResult(
      title: title,
      categoryId: categoryId,
      complete: draft.pending ? _validator.isComplete(transactionDraft) : true,
      errors: errors,
    );
  }

  String? _normalizeCategoryId(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}
