import "package:flutter/material.dart";
import "package:sembast/sembast.dart";
import "package:uuid/uuid.dart";

import "../features/image_attachment/data/image_storage_service.dart";
import "../features/image_attachment/domain/image_attachment_model.dart";
import "../features/voice_note/data/audio_storage_service.dart";
import "../features/voice_note/domain/audio_attachment_model.dart";
import "date_filter.dart";
import "models/category_model.dart";
import "models/transaction_model.dart";

class LedgerRepository extends ChangeNotifier {
  LedgerRepository(this._db);

  final Database _db;
  final AudioStorageService _audioStorage = AudioStorageService();
  final ImageStorageService _imageStorage = ImageStorageService();
  final _uuid = const Uuid();

  static final _meta = stringMapStoreFactory.store("meta");
  static final _categories = stringMapStoreFactory.store("categories");
  static final _transactions = stringMapStoreFactory.store("transactions");

  /// Fixed IDs for the built-in "Khác" fallback categories.
  static const kOtherExpenseId = "system_khac_expense";
  static const kOtherIncomeId = "system_khac_income";

  Future<void> ensureDefaults() async {
    final count = await _categories.count(_db);
    if (count == 0) {
      await _seedCategories();
    }
    // Always ensure the fallback "Khác" categories exist.
    await _ensureKhac();
    final meta = await _meta.record("app").get(_db);
    if (meta == null) {
      await _meta.record("app").put(_db, {"userName": "", "onboarded": false});
    }
  }

  Future<void> _ensureKhac() async {
    final khacExp = await _categories.record(kOtherExpenseId).get(_db);
    if (khacExp == null) {
      await _categories
          .record(kOtherExpenseId)
          .put(
            _db,
            const CategoryModel(
              id: kOtherExpenseId,
              name: "Khác",
              iconKey: "category",
              colorValue: 0xFF78909C,
              isIncome: false,
            ).toMap(),
          );
    }
    final khacInc = await _categories.record(kOtherIncomeId).get(_db);
    if (khacInc == null) {
      await _categories
          .record(kOtherIncomeId)
          .put(
            _db,
            const CategoryModel(
              id: kOtherIncomeId,
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

  Future<Map<String, Object?>> getMeta() async {
    final m = await _meta.record("app").get(_db);
    return Map<String, Object?>.from(m ?? {});
  }

  Future<void> setUserName(String name) async {
    final cur = await getMeta();
    cur["userName"] = name;
    await _meta.record("app").put(_db, cur);
    notifyListeners();
  }

  Future<void> setOnboarded(bool v) async {
    final cur = await getMeta();
    cur["onboarded"] = v;
    await _meta.record("app").put(_db, cur);
    notifyListeners();
  }

  Future<List<CategoryModel>> categories() async {
    final snap = await _categories.find(_db);
    return snap.map((r) => CategoryModel.fromMap(r.key, r.value)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  Future<void> upsertCategory(CategoryModel c) async {
    await _categories.record(c.id).put(_db, c.toMap());
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    await _categories.record(id).delete(_db);
    notifyListeners();
  }

  Future<List<TransactionModel>> allTransactions() async {
    final snap = await _transactions.find(_db);
    final list = snap
        .map((r) => TransactionModel.fromMap(r.key, r.value))
        .toList();
    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  List<TransactionModel> _inRange(
    List<TransactionModel> all,
    DateTimeRange range,
  ) {
    return all
        .where(
          (t) =>
              !t.occurredAt.isBefore(range.start) &&
              !t.occurredAt.isAfter(range.end),
        )
        .toList();
  }

  Future<Map<String, int>> homeSummary(DateFilterSelection filter) async {
    final all = await allTransactions();
    final range = filter.resolveRange(DateTime.now());
    final inR = _inRange(all, range);
    var income = 0;
    var expense = 0;
    for (final t in inR) {
      if (t.pending) continue;
      if (t.isIncome) {
        income += t.amountVnd;
      } else {
        expense += t.amountVnd;
      }
    }
    return {"income": income, "expense": expense};
  }

  Future<List<TransactionModel>> pendingForHome(
    DateFilterSelection filter,
  ) async {
    final all = await allTransactions();
    final range = filter.resolveRange(DateTime.now());
    final list = _inRange(all, range).where((t) => t.pending).toList();
    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list.take(3).toList();
  }

  Future<List<TransactionModel>> pendingAll(DateFilterSelection filter) async {
    final all = await allTransactions();
    final range = filter.resolveRange(DateTime.now());
    final list = _inRange(all, range).where((t) => t.pending).toList();
    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  Future<List<TransactionModel>> historyPage({
    required DateFilterSelection filter,
    required int offset,
    required int limit,
  }) async {
    final all = await allTransactions();
    final range = filter.resolveRange(DateTime.now());
    final list = _inRange(all, range).where((t) => !t.pending).toList();
    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    if (offset >= list.length) return [];
    return list.sublist(offset, (offset + limit).clamp(0, list.length));
  }

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

  Future<void> deleteTransaction(String id) async {
    final raw = await _transactions.record(id).get(_db);
    final t = raw == null ? null : TransactionModel.fromMap(id, raw);
    await _transactions.record(id).delete(_db);
    await _audioStorage.delete(t?.audio);
    await _deleteImages(t?.images ?? const []);
    notifyListeners();
  }

  Future<void> clearAllTransactions() async {
    final all = await allTransactions();
    await _transactions.delete(_db);
    for (final t in all) {
      await _audioStorage.delete(t.audio);
      await _deleteImages(t.images);
    }
    notifyListeners();
  }

  Future<void> confirmPending(String id) async {
    final raw = await _transactions.record(id).get(_db);
    if (raw == null) return;
    final t = TransactionModel.fromMap(id, raw);
    await putTransaction(t.copyWith(pending: false, complete: true));
  }

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

  Future<Map<String, int>> analyticsTotals({
    required AnalyticsPeriod period,
    DateTimeRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await allTransactions();
    final inR = _inRange(all, range).where((t) => !t.pending);
    var income = 0;
    var expense = 0;
    for (final t in inR) {
      if (t.isIncome) {
        income += t.amountVnd;
      } else {
        expense += t.amountVnd;
      }
    }
    return {"income": income, "expense": expense};
  }

  Future<Map<String, int>> categoryBreakdown({
    required AnalyticsPeriod period,
    required bool incomeSide,
    DateTimeRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await allTransactions();
    final inR = _inRange(
      all,
      range,
    ).where((t) => !t.pending && t.isIncome == incomeSide);
    final map = <String, int>{};
    for (final t in inR) {
      map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amountVnd;
    }
    return map;
  }

  Future<bool> categoryInUse(String categoryId) async {
    final all = await allTransactions();
    return all.any((t) => t.categoryId == categoryId);
  }

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

  Future<List<TransactionModel>> transactionsForCategory({
    required String categoryId,
    required AnalyticsPeriod period,
    DateTimeRange? custom,
  }) async {
    final now = DateTime.now();
    final range = period.resolve(now, custom: custom);
    final all = await allTransactions();
    return _inRange(
        all,
        range,
      ).where((t) => !t.pending && t.categoryId == categoryId).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
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
