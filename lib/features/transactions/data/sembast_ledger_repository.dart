import "dart:async";

import "package:sembast/sembast.dart";
import "package:smart_expense/core/utils/date_range.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/data/category_model_mapper.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/data/transaction_model_mapper.dart";
import "package:smart_expense/features/transactions/domain/entities/category.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/domain/services/ledger_query_service.dart";
import "package:smart_expense/features/transactions/data/attachments/audio_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:uuid/uuid.dart";

import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/features/transactions/data/models/transaction_model.dart";

class SembastLedgerRepository extends LedgerRepository {
  SembastLedgerRepository(this._db);

  final Database _db;
  final AudioStorageService _audioStorage = AudioStorageService();
  final ImageStorageService _imageStorage = ImageStorageService();
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final _uuid = const Uuid();
  final _queries = const LedgerQueryService();

  static final _meta = stringMapStoreFactory.store("meta");
  static final _categories = stringMapStoreFactory.store("categories");
  static final _transactions = stringMapStoreFactory.store("transactions");

  @override
  Stream<void> get changes => _changes.stream;

  @override
  Future<void> ensureDefaults() async {
    final count = await _categories.count(_db);
    if (count == 0) {
      await _seedCategories();
    }
    await _ensureKhac();
    final meta = await _meta.record("app").get(_db);
    if (meta == null) {
      await _meta.record("app").put(_db, {"userName": "", "onboarded": false});
    }
  }

  Future<void> _ensureKhac() async {
    final khacExp = await _categories
        .record(LedgerRepository.kOtherExpenseId)
        .get(_db);
    if (khacExp == null) {
      await _categories
          .record(LedgerRepository.kOtherExpenseId)
          .put(
            _db,
            const CategoryModel(
              id: LedgerRepository.kOtherExpenseId,
              name: "Khác",
              iconKey: "category",
              colorValue: 0xFF78909C,
              isIncome: false,
            ).toMap(),
          );
    }
    final khacInc = await _categories
        .record(LedgerRepository.kOtherIncomeId)
        .get(_db);
    if (khacInc == null) {
      await _categories
          .record(LedgerRepository.kOtherIncomeId)
          .put(
            _db,
            const CategoryModel(
              id: LedgerRepository.kOtherIncomeId,
              name: "Khác",
              iconKey: "category",
              colorValue: 0xFF78909C,
              isIncome: true,
            ).toMap(),
          );
    }
  }

  Future<void> _seedCategories() async {
    final defaults = <CategoryModel>[
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseFoodId,
        name: "Ăn uống",
        iconKey: "restaurant",
        colorValue: 0xFF0A6C67,
        isIncome: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseGroceryId,
        name: "Tạp hoá",
        iconKey: "local_grocery_store",
        colorValue: 0xFF2E8B57,
        isIncome: false,
        enabled: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseShoppingId,
        name: "Mua sắm",
        iconKey: "shopping_bag",
        colorValue: 0xFF2A86C9,
        isIncome: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseTransportId,
        name: "Di chuyển",
        iconKey: "train",
        colorValue: 0xFFE09C2B,
        isIncome: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseBillsId,
        name: "Hoá đơn",
        iconKey: "receipt_long",
        colorValue: 0xFF3B82F6,
        isIncome: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseEntertainmentId,
        name: "Giải trí",
        iconKey: "movie",
        colorValue: 0xFF7C3AED,
        isIncome: false,
        enabled: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseHealthId,
        name: "Sức khoẻ",
        iconKey: "medical_services",
        colorValue: 0xFF0EA5A2,
        isIncome: false,
        enabled: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseGiftId,
        name: "Quà tặng",
        iconKey: "card_giftcard",
        colorValue: 0xFFE11D48,
        isIncome: false,
        enabled: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseBeautyId,
        name: "Làm đẹp",
        iconKey: "spa",
        colorValue: 0xFF9333EA,
        isIncome: false,
        enabled: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseWorkId,
        name: "Công việc",
        iconKey: "work",
        colorValue: 0xFF6B7280,
        isIncome: false,
        enabled: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseTravelId,
        name: "Du lịch",
        iconKey: "flight",
        colorValue: 0xFFF97316,
        isIncome: false,
        enabled: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultExpenseCoffeeId,
        name: "Cà phê",
        iconKey: "local_cafe",
        colorValue: 0xFF8B5E3C,
        isIncome: false,
        enabled: false,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultIncomeSalaryId,
        name: "Lương",
        iconKey: "payments",
        colorValue: 0xFF4CAF50,
        isIncome: true,
      ),
      CategoryModel(
        id: LedgerRepository.kDefaultIncomeOtherId,
        name: "Thu nhập khác",
        iconKey: "savings",
        colorValue: 0xFF26A69A,
        isIncome: true,
        enabled: false,
      ),
    ];
    await _db.transaction((txn) async {
      for (final c in defaults) {
        await _categories.record(c.id).put(txn, c.toMap());
      }
    });
  }

  @override
  Future<Map<String, Object?>> getMeta() async {
    final m = await _meta.record("app").get(_db);
    return Map<String, Object?>.from(m ?? {});
  }

  @override
  Future<void> setUserName(String name) async {
    final cur = await getMeta();
    cur["userName"] = name;
    await _meta.record("app").put(_db, cur);
    _notifyChanged();
  }

  @override
  Future<void> setOnboarded(bool v) async {
    final cur = await getMeta();
    cur["onboarded"] = v;
    await _meta.record("app").put(_db, cur);
    _notifyChanged();
  }

  @override
  Future<List<LedgerCategory>> categories() async {
    final snap = await _categories.find(_db);
    return snap
        .map((r) => CategoryModel.fromMap(r.key, r.value).toEntity())
        .toList()
      ..sort(_compareCategories);
  }

  int _compareCategories(LedgerCategory a, LedgerCategory b) {
    final aIsOther = a.name == "Khác";
    final bIsOther = b.name == "Khác";
    if (aIsOther != bIsOther) return aIsOther ? 1 : -1;
    return a.name.compareTo(b.name);
  }

  @override
  Future<void> upsertCategory(LedgerCategory category) async {
    final model = category.toModel();
    await _categories.record(model.id).put(_db, model.toMap());
    _notifyChanged();
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _categories.record(id).delete(_db);
    _notifyChanged();
  }

  @override
  Future<List<LedgerTransaction>> allTransactions() async {
    final list = await _allTransactionModels();
    return list.map((transaction) => transaction.toEntity()).toList();
  }

  Future<List<TransactionModel>> _allTransactionModels() async {
    final snap = await _transactions.find(_db);
    final list = snap
        .map((r) => TransactionModel.fromMap(r.key, r.value))
        .toList();
    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  @override
  Future<Map<String, int>> homeSummary(DateFilterSelection filter) async {
    final all = await _allTransactionModels();
    final range = filter.resolveRange(DateTime.now());
    return _queries.confirmedTotals(_entities(all), range).toLegacyMap();
  }

  @override
  Future<List<LedgerTransaction>> pendingForHome(
    DateFilterSelection filter,
  ) async {
    final all = await _allTransactionModels();
    final range = filter.resolveRange(DateTime.now());
    return _queries.pendingInRange(_entities(all), range, limit: 3);
  }

  @override
  Future<List<LedgerTransaction>> pendingAll(DateFilterSelection filter) async {
    final all = await _allTransactionModels();
    final range = filter.resolveRange(DateTime.now());
    return _queries.pendingInRange(_entities(all), range);
  }

  @override
  Future<List<LedgerTransaction>> historyPage({
    required DateFilterSelection filter,
    required int offset,
    required int limit,
  }) async {
    final all = await _allTransactionModels();
    final range = filter.resolveRange(DateTime.now());
    return _queries.confirmedHistoryPage(
      _entities(all),
      range,
      offset: offset,
      limit: limit,
    );
  }

  @override
  Future<void> putTransaction(LedgerTransaction transaction) async {
    final t = transaction.toModel();
    final raw = await _transactions.record(t.id).get(_db);
    final previous = raw == null ? null : TransactionModel.fromMap(t.id, raw);
    await _transactions.record(t.id).put(_db, t.toMap());
    final previousAudio = previous?.audio;
    if (previousAudio != null && previousAudio.id != t.audio?.id) {
      await _audioStorage.delete(previousAudio);
    }
    await _deleteRemovedImages(previous?.images ?? const [], t.images);
    _notifyChanged();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final raw = await _transactions.record(id).get(_db);
    final t = raw == null ? null : TransactionModel.fromMap(id, raw);
    await _transactions.record(id).delete(_db);
    await _audioStorage.delete(t?.audio);
    await _deleteImages(t?.images ?? const []);
    _notifyChanged();
  }

  @override
  Future<void> clearAllTransactions() async {
    final all = await _allTransactionModels();
    await _transactions.delete(_db);
    for (final t in all) {
      await _audioStorage.delete(t.audio);
      await _deleteImages(t.images);
    }
    _notifyChanged();
  }

  @override
  Future<void> confirmPending(String id) async {
    final raw = await _transactions.record(id).get(_db);
    if (raw == null) return;
    final t = TransactionModel.fromMap(id, raw);
    await putTransaction(t.copyWith(pending: false, complete: true).toEntity());
  }

  @override
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
  }) async {
    final t = TransactionModel(
      id: _uuid.v4(),
      title: title,
      amountVnd: amountVnd,
      isIncome: isIncome,
      categoryId: categoryId,
      occurredAt: at ?? DateTime.now(),
      pending: pending,
      complete: complete,
      note: note,
      audio: audio,
      images: images,
    );
    await putTransaction(t.toEntity());
    return t.toEntity();
  }

  @override
  Future<Map<String, int>> analyticsTotals({
    required AnalyticsPeriod period,
    AppDateRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await _allTransactionModels();
    return _queries.confirmedTotals(_entities(all), range).toLegacyMap();
  }

  @override
  Future<Map<String, int>> categoryBreakdown({
    required AnalyticsPeriod period,
    required bool incomeSide,
    AppDateRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await _allTransactionModels();
    return _queries.categoryBreakdown(
      _entities(all),
      range,
      incomeSide: incomeSide,
    );
  }

  @override
  Future<bool> categoryInUse(String categoryId) async {
    final all = await _allTransactionModels();
    return all.any((t) => t.categoryId == categoryId);
  }

  @override
  Future<LedgerCategory> createCategory({
    required String name,
    required bool isIncome,
    required String iconKey,
    required int colorValue,
  }) async {
    final c = CategoryModel(
      id: _uuid.v4(),
      name: name,
      iconKey: iconKey,
      colorValue: colorValue,
      isIncome: isIncome,
    );
    await upsertCategory(c.toEntity());
    return c.toEntity();
  }

  @override
  Future<List<LedgerTransaction>> transactionsForCategory({
    required String categoryId,
    required AnalyticsPeriod period,
    AppDateRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await _allTransactionModels();
    return _queries.transactionsForCategory(
      _entities(all),
      range,
      categoryId: categoryId,
    );
  }

  List<LedgerTransaction> _entities(List<TransactionModel> transactions) {
    return transactions.map((transaction) => transaction.toEntity()).toList();
  }

  Future<void> _deleteRemovedImages(
    List<ImageAttachmentModel> previous,
    List<ImageAttachmentModel> next,
  ) async {
    final nextIds = next.map((image) => image.id).toSet();
    final removed = previous.where((image) => !nextIds.contains(image.id));
    await _deleteImages(removed);
  }

  Future<void> _deleteImages(Iterable<ImageAttachmentModel> images) async {
    for (final image in images) {
      await _imageStorage.delete(image);
    }
  }

  void _notifyChanged() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }

  Future<void> dispose() async {
    await _changes.close();
  }
}
