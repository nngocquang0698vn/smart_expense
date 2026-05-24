import "package:smart_expense/core/utils/date_range.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";

/// Contract for ledger persistence and queries.
abstract class LedgerRepository {
  static const kDefaultExpenseFoodId = "default_expense_food";
  static const kDefaultExpenseGroceryId = "default_expense_grocery";
  static const kDefaultExpenseShoppingId = "default_expense_shopping";
  static const kDefaultExpenseTransportId = "default_expense_transport";
  static const kDefaultExpenseBillsId = "default_expense_bills";
  static const kDefaultExpenseEntertainmentId = "default_expense_entertainment";
  static const kDefaultExpenseHealthId = "default_expense_health";
  static const kDefaultExpenseGiftId = "default_expense_gift";
  static const kDefaultExpenseBeautyId = "default_expense_beauty";
  static const kDefaultExpenseWorkId = "default_expense_work";
  static const kDefaultExpenseTravelId = "default_expense_travel";
  static const kDefaultExpenseCoffeeId = "default_expense_coffee";
  static const kOtherExpenseId = "system_khac_expense";
  static const kDefaultIncomeSalaryId = "default_income_salary";
  static const kDefaultIncomeOtherId = "default_income_other";
  static const kOtherIncomeId = "system_khac_income";

  Stream<void> get changes;

  Future<void> ensureDefaults();

  Future<Map<String, Object?>> getMeta();
  Future<void> setUserName(String name);
  Future<void> setOnboarded(bool v);

  Future<List<LedgerCategory>> categories();
  Future<void> upsertCategory(LedgerCategory category);
  Future<void> deleteCategory(String id);

  Future<List<LedgerTransaction>> allTransactions();
  Future<Map<String, int>> homeSummary(DateFilterSelection filter);
  Future<List<LedgerTransaction>> pendingForHome(DateFilterSelection filter);
  Future<List<LedgerTransaction>> pendingAll(DateFilterSelection filter);
  Future<List<LedgerTransaction>> historyPage({
    required DateFilterSelection filter,
    required int offset,
    required int limit,
  });

  Future<void> putTransaction(LedgerTransaction transaction);
  Future<void> deleteTransaction(String id);
  Future<void> clearAllTransactions();
  Future<void> confirmPending(String id);

  Future<LedgerTransaction> addQuick({
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
    AppDateRange? custom,
  });

  Future<Map<String, int>> categoryBreakdown({
    required AnalyticsPeriod period,
    required bool incomeSide,
    AppDateRange? custom,
  });

  Future<bool> categoryInUse(String categoryId);

  Future<LedgerCategory> createCategory({
    required String name,
    required bool isIncome,
    required String iconKey,
    required int colorValue,
  });

  Future<List<LedgerTransaction>> transactionsForCategory({
    required String categoryId,
    required AnalyticsPeriod period,
    AppDateRange? custom,
  });
}
