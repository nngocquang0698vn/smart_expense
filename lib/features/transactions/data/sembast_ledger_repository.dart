import "package:flutter/material.dart";
import "package:sembast/sembast.dart";
import "package:smart_expense/core/utils/date_range.dart";
import "package:smart_expense/features/transactions/data/attachments/image_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";
import "package:smart_expense/features/transactions/data/transaction_model_mapper.dart";
import "package:smart_expense/features/transactions/domain/entities/ledger_transaction.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";
import "package:smart_expense/features/transactions/domain/services/ledger_query_service.dart";
import "package:smart_expense/features/transactions/data/attachments/audio_storage_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:uuid/uuid.dart";

import "package:smart_expense/features/transactions/data/date_filter.dart";
import "package:smart_expense/features/transactions/data/models/category_model.dart";
import "package:smart_expense/features/transactions/data/models/transaction_model.dart";

class SembastLedgerRepository extends LedgerRepository {
  SembastLedgerRepository(this._db);

  final Database _db;
  final AudioStorageService _audioStorage = AudioStorageService();
  final ImageStorageService _imageStorage = ImageStorageService();
  final _uuid = const Uuid();
  final _queries = const LedgerQueryService();

  static final _meta = stringMapStoreFactory.store("meta");
  static final _categories = stringMapStoreFactory.store("categories");
  static final _transactions = stringMapStoreFactory.store("transactions");

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
        id: _uuid.v4(),
        name: "Ăn uống",
        iconKey: "restaurant",
        colorValue: 0xFF0A6C67,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Tạp hoá",
        iconKey: "local_grocery_store",
        colorValue: 0xFF2E8B57,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Mua sắm",
        iconKey: "shopping_bag",
        colorValue: 0xFF2A86C9,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Di chuyển",
        iconKey: "train",
        colorValue: 0xFFE09C2B,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Hoá đơn",
        iconKey: "receipt_long",
        colorValue: 0xFF3B82F6,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Giải trí",
        iconKey: "movie",
        colorValue: 0xFF7C3AED,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Sức khoẻ",
        iconKey: "medical_services",
        colorValue: 0xFF0EA5A2,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Quà tặng",
        iconKey: "card_giftcard",
        colorValue: 0xFFE11D48,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Làm đẹp",
        iconKey: "spa",
        colorValue: 0xFF9333EA,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Công việc",
        iconKey: "work",
        colorValue: 0xFF6B7280,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Du lịch",
        iconKey: "flight",
        colorValue: 0xFFF97316,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Cà phê",
        iconKey: "local_cafe",
        colorValue: 0xFF8B5E3C,
        isIncome: false,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Lương",
        iconKey: "payments",
        colorValue: 0xFF4CAF50,
        isIncome: true,
      ),
      CategoryModel(
        id: _uuid.v4(),
        name: "Thu nhập khác",
        iconKey: "savings",
        colorValue: 0xFF26A69A,
        isIncome: true,
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
    notifyListeners();
  }

  @override
  Future<void> setOnboarded(bool v) async {
    final cur = await getMeta();
    cur["onboarded"] = v;
    await _meta.record("app").put(_db, cur);
    notifyListeners();
  }

  @override
  Future<List<CategoryModel>> categories() async {
    final snap = await _categories.find(_db);
    return snap.map((r) => CategoryModel.fromMap(r.key, r.value)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  @override
  Future<void> upsertCategory(CategoryModel c) async {
    await _categories.record(c.id).put(_db, c.toMap());
    notifyListeners();
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _categories.record(id).delete(_db);
    notifyListeners();
  }

  @override
  Future<List<TransactionModel>> allTransactions() async {
    final snap = await _transactions.find(_db);
    final list = snap
        .map((r) => TransactionModel.fromMap(r.key, r.value))
        .toList();
    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  @override
  Future<Map<String, int>> homeSummary(DateFilterSelection filter) async {
    final all = await allTransactions();
    final range = filter.resolveRange(DateTime.now());
    return _queries
        .confirmedTotals(_entities(all), _appRange(range))
        .toLegacyMap();
  }

  @override
  Future<List<TransactionModel>> pendingForHome(
    DateFilterSelection filter,
  ) async {
    final all = await allTransactions();
    final range = filter.resolveRange(DateTime.now());
    return _modelsForEntities(
      all,
      _queries.pendingInRange(_entities(all), _appRange(range), limit: 3),
    );
  }

  @override
  Future<List<TransactionModel>> pendingAll(DateFilterSelection filter) async {
    final all = await allTransactions();
    final range = filter.resolveRange(DateTime.now());
    return _modelsForEntities(
      all,
      _queries.pendingInRange(_entities(all), _appRange(range)),
    );
  }

  @override
  Future<List<TransactionModel>> historyPage({
    required DateFilterSelection filter,
    required int offset,
    required int limit,
  }) async {
    final all = await allTransactions();
    final range = filter.resolveRange(DateTime.now());
    return _modelsForEntities(
      all,
      _queries.confirmedHistoryPage(
        _entities(all),
        _appRange(range),
        offset: offset,
        limit: limit,
      ),
    );
  }

  @override
  Future<void> putTransaction(TransactionModel t) async {
    final raw = await _transactions.record(t.id).get(_db);
    final previous = raw == null ? null : TransactionModel.fromMap(t.id, raw);
    await _transactions.record(t.id).put(_db, t.toMap());
    final previousAudio = previous?.audio;
    if (previousAudio != null && previousAudio.id != t.audio?.id) {
      await _audioStorage.delete(previousAudio);
    }
    await _deleteRemovedImages(previous?.images ?? const [], t.images);
    notifyListeners();
  }

  @override
  Future<void> deleteTransaction(String id) async {
    final raw = await _transactions.record(id).get(_db);
    final t = raw == null ? null : TransactionModel.fromMap(id, raw);
    await _transactions.record(id).delete(_db);
    await _audioStorage.delete(t?.audio);
    await _deleteImages(t?.images ?? const []);
    notifyListeners();
  }

  @override
  Future<void> clearAllTransactions() async {
    final all = await allTransactions();
    await _transactions.delete(_db);
    for (final t in all) {
      await _audioStorage.delete(t.audio);
      await _deleteImages(t.images);
    }
    notifyListeners();
  }

  @override
  Future<void> confirmPending(String id) async {
    final raw = await _transactions.record(id).get(_db);
    if (raw == null) return;
    final t = TransactionModel.fromMap(id, raw);
    await putTransaction(t.copyWith(pending: false, complete: true));
  }

  @override
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
    await putTransaction(t);
    return t;
  }

  @override
  Future<Map<String, int>> analyticsTotals({
    required AnalyticsPeriod period,
    DateTimeRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await allTransactions();
    return _queries
        .confirmedTotals(_entities(all), _appRange(range))
        .toLegacyMap();
  }

  @override
  Future<Map<String, int>> categoryBreakdown({
    required AnalyticsPeriod period,
    required bool incomeSide,
    DateTimeRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await allTransactions();
    return _queries.categoryBreakdown(
      _entities(all),
      _appRange(range),
      incomeSide: incomeSide,
    );
  }

  @override
  Future<bool> categoryInUse(String categoryId) async {
    final all = await allTransactions();
    return all.any((t) => t.categoryId == categoryId);
  }

  @override
  Future<CategoryModel> createCategory({
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
    await upsertCategory(c);
    return c;
  }

  @override
  Future<List<TransactionModel>> transactionsForCategory({
    required String categoryId,
    required AnalyticsPeriod period,
    DateTimeRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await allTransactions();
    return _modelsForEntities(
      all,
      _queries.transactionsForCategory(
        _entities(all),
        _appRange(range),
        categoryId: categoryId,
      ),
    );
  }

  List<LedgerTransaction> _entities(List<TransactionModel> transactions) {
    return transactions.map((transaction) => transaction.toEntity()).toList();
  }

  List<TransactionModel> _modelsForEntities(
    List<TransactionModel> source,
    List<LedgerTransaction> entities,
  ) {
    final byId = {
      for (final transaction in source) transaction.id: transaction,
    };
    return [
      for (final entity in entities)
        if (byId[entity.id] != null) byId[entity.id]!,
    ];
  }

  AppDateRange _appRange(DateTimeRange range) {
    return AppDateRange(start: range.start, end: range.end);
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
}
