import "package:smart_expense/features/transactions/data/voice_transaction_demo_api_client.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

class VoiceTransactionFormPatch {
  const VoiceTransactionFormPatch({
    this.title,
    this.amountVnd,
    required this.isIncome,
    required this.categoryId,
    this.note,
    this.occurredAt,
    required this.pending,
  });

  final String? title;
  final int? amountVnd;
  final bool isIncome;
  final String? categoryId;
  final String? note;
  final DateTime? occurredAt;
  final bool pending;
}

class VoiceTransactionDemoMapper {
  const VoiceTransactionDemoMapper();

  VoiceTransactionFormPatch map({
    required VoiceTransactionDemoResponse response,
    required List<LedgerCategory> categories,
    required String? currentCategoryId,
  }) {
    final draft = response.transactionDraft;
    final categoryId = resolveCategoryId(
      draft: draft,
      categories: categories,
      currentCategoryId: currentCategoryId,
    );
    return VoiceTransactionFormPatch(
      title: _clean(draft.title),
      amountVnd: draft.amountVnd,
      isIncome: draft.isIncome,
      categoryId: categoryId,
      note: _clean(draft.note) ?? _clean(response.transcript),
      occurredAt: draft.transactionDate,
      pending: true,
    );
  }

  String? resolveCategoryId({
    required VoiceTransactionDraftResponse draft,
    required List<LedgerCategory> categories,
    required String? currentCategoryId,
  }) {
    final sideCategories = categories
        .where(
          (category) => category.enabled && category.isIncome == draft.isIncome,
        )
        .toList();

    final byId = _firstWhereOrNull(
      sideCategories,
      (category) => _clean(category.id) == _clean(draft.categoryId),
    );
    if (byId != null) return byId.id;

    final keyId = _categoryIdForKey(draft.categoryKey, draft.isIncome);
    if (keyId != null) {
      final byKey = _firstWhereOrNull(
        sideCategories,
        (category) => category.id == keyId,
      );
      if (byKey != null) return byKey.id;
    }

    final wantedName = _normalizeName(draft.categoryName);
    if (wantedName != null) {
      final byName = _firstWhereOrNull(
        sideCategories,
        (category) => _normalizeName(category.name) == wantedName,
      );
      if (byName != null) return byName.id;
    }

    final fallbackId = draft.isIncome
        ? LedgerRepository.kOtherIncomeId
        : LedgerRepository.kOtherExpenseId;
    final fallback = _firstWhereOrNull(
      sideCategories,
      (category) => category.id == fallbackId,
    );
    if (fallback != null) return fallback.id;

    final current = _firstWhereOrNull(
      sideCategories,
      (category) => category.id == currentCategoryId,
    );
    return current?.id;
  }

  static String? _categoryIdForKey(String? rawKey, bool isIncome) {
    final key = _clean(rawKey);
    if (key == null) return null;
    return switch (key) {
      "food" => LedgerRepository.kDefaultExpenseFoodId,
      "shopping" => LedgerRepository.kDefaultExpenseShoppingId,
      "transport" => LedgerRepository.kDefaultExpenseTransportId,
      "bills" => LedgerRepository.kDefaultExpenseBillsId,
      "other_expense" => LedgerRepository.kOtherExpenseId,
      "salary" => LedgerRepository.kDefaultIncomeSalaryId,
      "other_income" => LedgerRepository.kOtherIncomeId,
      _ =>
        isIncome
            ? LedgerRepository.kOtherIncomeId
            : LedgerRepository.kOtherExpenseId,
    };
  }

  static String? _clean(String? value) {
    final cleaned = value?.trim();
    return cleaned == null || cleaned.isEmpty ? null : cleaned;
  }

  static String? _normalizeName(String? value) {
    final cleaned = _clean(value);
    if (cleaned == null) return null;
    return cleaned.toLowerCase();
  }

  static T? _firstWhereOrNull<T>(
    Iterable<T> items,
    bool Function(T item) test,
  ) {
    for (final item in items) {
      if (test(item)) return item;
    }
    return null;
  }
}
