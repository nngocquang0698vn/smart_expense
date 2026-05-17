import "package:flutter/material.dart";

import "../../../../data/date_filter.dart";
import "../../../../data/models/category_model.dart";
import "../../../../data/models/transaction_model.dart";
import "../../../image_attachment/domain/image_attachment_model.dart";
import "../../../voice_note/domain/audio_attachment_model.dart";

/// Contract for ledger persistence and queries.
abstract class LedgerRepository extends ChangeNotifier {
  static const kOtherExpenseId = "system_khac_expense";
  static const kOtherIncomeId = "system_khac_income";

  Future<void> ensureDefaults();

  Future<Map<String, Object?>> getMeta();
  Future<void> setUserName(String name);
  Future<void> setOnboarded(bool v);

  Future<List<CategoryModel>> categories();
  Future<void> upsertCategory(CategoryModel c);
  Future<void> deleteCategory(String id);

  Future<List<TransactionModel>> allTransactions();
  Future<Map<String, int>> homeSummary(DateFilterSelection filter);
  Future<List<TransactionModel>> pendingForHome(DateFilterSelection filter);
  Future<List<TransactionModel>> pendingAll(DateFilterSelection filter);
  Future<List<TransactionModel>> historyPage({
    required DateFilterSelection filter,
    required int offset,
    required int limit,
  });

  Future<void> putTransaction(TransactionModel t);
  Future<void> deleteTransaction(String id);
  Future<void> clearAllTransactions();
  Future<void> confirmPending(String id);

  Future<TransactionModel> addQuick({
    required String title,
    required int amountVnd,
    required bool isIncome,
    required String categoryId,
    DateTime? at,
    bool pending = false,
    bool complete = true,
    String? note,
    AudioAttachmentModel? audio,
    List<ImageAttachmentModel> images = const [],
  });

  Future<Map<String, int>> analyticsTotals({
    required AnalyticsPeriod period,
    DateTimeRange? custom,
  });

  Future<Map<String, int>> categoryBreakdown({
    required AnalyticsPeriod period,
    required bool incomeSide,
    DateTimeRange? custom,
  });

  Future<bool> categoryInUse(String categoryId);

  Future<CategoryModel> createCategory({
    required String name,
    required bool isIncome,
    required String iconKey,
    required int colorValue,
  });

  Future<List<TransactionModel>> transactionsForCategory({
    required String categoryId,
    required AnalyticsPeriod period,
    DateTimeRange? custom,
  });
}
