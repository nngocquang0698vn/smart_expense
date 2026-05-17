import "dart:ui" as ui;

import "package:flutter/services.dart";

import "../core/audio_storage_helper.dart";
import "../features/categories/application/category_selection_resolver.dart";
import "../features/image_attachment/data/image_storage_service.dart";
import "../features/image_attachment/domain/image_attachment_model.dart";
import "../features/voice_note/data/audio_storage_service.dart";
import "../features/voice_note/domain/audio_attachment_model.dart";
import "ledger_repository.dart";

/// Clears all transactions, sets the username to "Johny Nguyễn", and seeds
/// realistic income/expense records spanning ~3 months.
///
/// **Date offset**: All dates are shifted so that the seed's reference end-date
/// (2026-05-10) always maps to *today*. This keeps the data looking "recent"
/// regardless of when the demo is run.
///
/// **Pending transactions**: 10 recent entries (audio / bill / quick) are left
/// as pending to showcase the reconciliation flow.
Future<void> populateJohnyData(LedgerRepository repo) async {
  await repo.clearAllTransactions();
  await repo.setUserName("Johny Nguyễn");

  // ── Date offset helpers ───────────────────────────────────────────────────
  final today = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  final refEnd = DateTime(2026, 5, 10); // reference "today" in the seed
  final shiftDays = today.difference(refEnd).inDays;

  DateTime d(int year, int month, int day) =>
      DateTime(year, month, day).add(Duration(days: shiftDays));

  // "today - N days" for pending entries
  DateTime recent(int daysAgo) => today.subtract(Duration(days: daysAgo));

  // ── Load demo media assets ────────────────────────────────────────────────
  final audioBytes = await rootBundle.load("assets/demo/audio_demo.mp3");
  final audioData = audioBytes.buffer.asUint8List();
  final audioStorage = AudioStorageService();
  Future<AudioAttachmentModel> demoAudio() {
    return audioStorage.saveRecording(
      bytes: audioData,
      duration: const Duration(seconds: 8),
      mimeType: AudioStorageHelper.contentTypeForBytes(audioData),
      extension: AudioStorageHelper.extensionForBytes(audioData),
    );
  }

  final imageBytes = await rootBundle.load("assets/demo/bill_demo.jpg");
  final imageData = imageBytes.buffer.asUint8List();
  final imageSize = await _imageSize(imageData);
  final imageStorage = ImageStorageService();
  Future<ImageAttachmentModel> demoImage() {
    return imageStorage.save(
      bytes: imageData,
      mimeType: "image/jpeg",
      extension: ".jpg",
      width: imageSize.width,
      height: imageSize.height,
    );
  }

  // ── Category lookup ───────────────────────────────────────────────────────
  final cats = await repo.categories();
  final categoryLookup = CategoryNameLookup(cats);
  String cat(String name, {required bool isIncome}) {
    final id = categoryLookup.idFor(
      name: name,
      isIncome: isIncome,
      fallbackName: "Khác",
    );
    if (id == null) {
      throw StateError(
        "Không tìm thấy danh mục demo cho ${isIncome ? "thu" : "chi"}: $name",
      );
    }
    return id;
  }

  // ── Helper: add a fully-reconciled transaction ────────────────────────────
  Future<void> add({
    required String title,
    required int amount,
    required bool isIncome,
    required String category,
    required DateTime date,
    String? note,
    bool audio = false,
    bool image = false,
  }) async {
    await repo.addQuick(
      title: title,
      amountVnd: amount,
      isIncome: isIncome,
      categoryId: cat(category, isIncome: isIncome),
      at: date,
      pending: false,
      complete: true,
      note: note,
      audio: audio ? await demoAudio() : null,
      images: image ? [await demoImage()] : const [],
    );
  }

  // ── Helper: add a pending transaction ────────────────────────────────────
  // `complete` is derived: amount > 0 means info is sufficient to confirm.
  Future<void> addPending({
    required String title,
    required int amount,
    required String category,
    required bool isIncome,
    required DateTime date,
    String? note,
    bool audio = false,
    bool image = false,
  }) async {
    if (!audio && !image) {
      throw ArgumentError(
        "Pending demo transaction must include audio or image: $title",
      );
    }
    await repo.addQuick(
      title: title,
      amountVnd: amount,
      isIncome: isIncome,
      categoryId: cat(category, isIncome: isIncome),
      at: date,
      pending: true,
      complete: amount > 0,
      note: note,
      audio: audio ? await demoAudio() : null,
      images: image ? [await demoImage()] : const [],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // FEBRUARY 2026
  // Income: 45 000 000  |  Expense ≈ 23 890 000
  // ══════════════════════════════════════════════════════════════════════════
  await add(
    title: "Thuê nhà tháng 2",
    amount: 9000000,
    isIncome: false,
    category: "Hoá đơn",
    date: d(2026, 2, 1),
    note: "Phòng trọ Q.Bình Thạnh",
    image: true,
  );
  await add(
    title: "Học tiếng Anh",
    amount: 2500000,
    isIncome: false,
    category: "Công việc",
    date: d(2026, 2, 3),
    note: "Trung tâm anh ngữ ILA tháng 2",
  );
  await add(
    title: "Lương tháng 2",
    amount: 45000000,
    isIncome: true,
    category: "Lương",
    date: d(2026, 2, 5),
    note: "Chuyển khoản từ công ty",
  );
  await add(
    title: "Cà phê sáng",
    amount: 65000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 2, 6),
  );
  await add(
    title: "Phở sáng",
    amount: 80000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 7),
  );
  await add(
    title: "Grab đi làm",
    amount: 110000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 2, 7),
  );
  await add(
    title: "Tiền điện nước & internet",
    amount: 820000,
    isIncome: false,
    category: "Hoá đơn",
    date: d(2026, 2, 8),
    image: true,
  );
  await add(
    title: "Cà phê chiều đồng nghiệp",
    amount: 140000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 2, 9),
  );
  await add(
    title: "Ăn tối nhà hàng",
    amount: 380000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 10),
  );
  await add(
    title: "Cơm trưa bình dân",
    amount: 65000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 11),
  );
  await add(
    title: "Cà phê làm việc",
    amount: 60000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 2, 11),
  );
  await add(
    title: "Mua quần áo (sale Tết)",
    amount: 1850000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 2, 12),
    note: "Áo + quần jeans Uniqlo",
  );
  await add(
    title: "Tạp hoá cuối tuần",
    amount: 350000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 2, 13),
  );
  await add(
    title: "Quà Valentine",
    amount: 950000,
    isIncome: false,
    category: "Quà tặng",
    date: d(2026, 2, 14),
    note: "Hoa + socola cho bạn gái",
  );
  await add(
    title: "Ăn tối Valentine",
    amount: 750000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 14),
    note: "Nhà hàng Ý Q.1",
  );
  await add(
    title: "Cà phê sáng",
    amount: 70000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 2, 15),
  );
  await add(
    title: "Grab đi làm",
    amount: 120000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 2, 15),
  );
  await add(
    title: "Cơm trưa",
    amount: 70000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 16),
  );
  await add(
    title: "Mua chuột không dây",
    amount: 650000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 2, 17),
    note: "Logitech M750",
  );
  await add(
    title: "Xem phim cuối tuần",
    amount: 280000,
    isIncome: false,
    category: "Giải trí",
    date: d(2026, 2, 18),
  );
  await add(
    title: "Nhậu cuối tuần",
    amount: 520000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 18),
    note: "Bia hơi Hà Nội cùng team",
  );
  await add(
    title: "Cà phê",
    amount: 75000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 2, 19),
  );
  await add(
    title: "Tạp hoá",
    amount: 280000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 2, 19),
  );
  await add(
    title: "Cơm trưa",
    amount: 65000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 20),
  );
  await add(
    title: "Grab về nhà",
    amount: 95000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 2, 20),
  );
  await add(
    title: "Mua giày thể thao",
    amount: 1800000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 2, 21),
    note: "Nike Air Max – giảm giá cuối mùa",
  );
  await add(
    title: "Cà phê sáng",
    amount: 80000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 2, 22),
  );
  await add(
    title: "Karaoke cùng bạn bè",
    amount: 280000,
    isIncome: false,
    category: "Giải trí",
    date: d(2026, 2, 22),
  );
  await add(
    title: "Ăn tối",
    amount: 250000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 23),
  );
  await add(
    title: "Khám răng định kỳ",
    amount: 800000,
    isIncome: false,
    category: "Sức khoẻ",
    date: d(2026, 2, 24),
    image: true,
  );
  await add(
    title: "Grab đi làm",
    amount: 130000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 2, 25),
  );
  await add(
    title: "Cà phê sáng",
    amount: 65000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 2, 25),
  );
  await add(
    title: "Cơm trưa",
    amount: 70000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 2, 26),
  );
  await add(
    title: "Streaming phim (Netflix)",
    amount: 200000,
    isIncome: false,
    category: "Giải trí",
    date: d(2026, 2, 27),
  );
  await add(
    title: "Tạp hoá cuối tháng",
    amount: 300000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 2, 28),
  );
  await add(
    title: "Mua sắm online",
    amount: 850000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 2, 28),
    note: "Shopee – áo thun + phụ kiện",
  );

  // ══════════════════════════════════════════════════════════════════════════
  // MARCH 2026
  // Income: 45 000 000  |  Expense ≈ 26 625 000
  // ══════════════════════════════════════════════════════════════════════════
  await add(
    title: "Thuê nhà tháng 3",
    amount: 9000000,
    isIncome: false,
    category: "Hoá đơn",
    date: d(2026, 3, 1),
    note: "Phòng trọ Q.Bình Thạnh",
    image: true,
  );
  await add(
    title: "Học tiếng Anh",
    amount: 2500000,
    isIncome: false,
    category: "Công việc",
    date: d(2026, 3, 3),
    note: "ILA tháng 3",
    audio: true,
  );
  await add(
    title: "Lương tháng 3",
    amount: 45000000,
    isIncome: true,
    category: "Lương",
    date: d(2026, 3, 5),
  );
  await add(
    title: "Cà phê sáng",
    amount: 70000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 3, 6),
  );
  await add(
    title: "Phở sáng",
    amount: 80000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 7),
  );
  await add(
    title: "Grab đi làm",
    amount: 115000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 3, 7),
  );
  await add(
    title: "Tiền điện nước & internet",
    amount: 780000,
    isIncome: false,
    category: "Hoá đơn",
    date: d(2026, 3, 8),
    image: true,
  );
  await add(
    title: "Đặt sách lập trình",
    amount: 500000,
    isIncome: false,
    category: "Công việc",
    date: d(2026, 3, 8),
    note: "Clean Code + System Design",
  );
  await add(
    title: "Cà phê chiều",
    amount: 90000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 3, 9),
  );
  await add(
    title: "Cơm trưa",
    amount: 65000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 10),
  );
  await add(
    title: "Ăn tối với bạn",
    amount: 350000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 10),
  );
  await add(
    title: "Tạp hoá",
    amount: 280000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 3, 11),
  );
  await add(
    title: "Cà phê",
    amount: 75000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 3, 12),
  );
  await add(
    title: "Cơm bình dân",
    amount: 70000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 13),
  );
  await add(
    title: "Grab về nhà",
    amount: 100000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 3, 13),
  );
  await add(
    title: "Mua áo sơ mi công sở",
    amount: 480000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 3, 14),
  );
  await add(
    title: "Ăn tối hẹn hò",
    amount: 450000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 14),
    note: "Nhà hàng Nhật Q.3",
  );
  await add(
    title: "Cà phê sáng",
    amount: 75000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 3, 15),
  );
  await add(
    title: "Ăn tối nhà hàng",
    amount: 450000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 16),
  );
  await add(
    title: "Bia với đồng nghiệp sau giờ làm",
    amount: 300000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 17),
  );
  await add(
    title: "Tạp hoá",
    amount: 260000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 3, 17),
  );
  await add(
    title: "Mua quần áo hè",
    amount: 1200000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 3, 18),
    note: "Zara sale – 2 áo + 1 quần",
  );
  await add(
    title: "Nhậu với bạn cũ",
    amount: 580000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 19),
    audio: true,
  );
  await add(
    title: "Cà phê",
    amount: 65000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 3, 19),
  );
  await add(
    title: "Cơm trưa",
    amount: 70000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 20),
  );
  await add(
    title: "Grab đi làm",
    amount: 95000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 3, 20),
  );
  await add(
    title: "Tai nghe bluetooth",
    amount: 750000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 3, 21),
    note: "Ugreen HiTune T3",
  );
  await add(
    title: "Cà phê",
    amount: 80000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 3, 22),
  );
  await add(
    title: "Xem phim cuối tuần",
    amount: 320000,
    isIncome: false,
    category: "Giải trí",
    date: d(2026, 3, 23),
  );
  await add(
    title: "Trip Đà Lạt cuối tuần",
    amount: 3500000,
    isIncome: false,
    category: "Du lịch",
    date: d(2026, 3, 24),
    note: "Vé xe + khách sạn + ăn uống 2 ngày",
    audio: true,
  );
  await add(
    title: "Mua đồ lưu niệm Đà Lạt",
    amount: 800000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 3, 25),
    note: "Quà cho gia đình và bạn bè",
  );
  await add(
    title: "Cơm trưa",
    amount: 70000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 27),
  );
  await add(
    title: "Cà phê",
    amount: 65000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 3, 27),
  );
  await add(
    title: "Tạp hoá",
    amount: 280000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 3, 28),
  );
  await add(
    title: "Mua sắm cuối tháng",
    amount: 1500000,
    isIncome: false,
    category: "Mua sắm",
    date: d(2026, 3, 29),
    note: "Shopee – giày sandal + ví",
  );
  await add(
    title: "Nhậu cuối tháng",
    amount: 450000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 3, 30),
  );
  await add(
    title: "Grab",
    amount: 110000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 3, 30),
  );
  await add(
    title: "Khám sức khoẻ định kỳ",
    amount: 600000,
    isIncome: false,
    category: "Sức khoẻ",
    date: d(2026, 3, 31),
    image: true,
  );

  // ══════════════════════════════════════════════════════════════════════════
  // APRIL 2026 – SAVINGS MODE
  // Income: 45 000 000  |  Expense ≈ 15 645 000
  // ══════════════════════════════════════════════════════════════════════════
  await add(
    title: "Thuê nhà tháng 4",
    amount: 9000000,
    isIncome: false,
    category: "Hoá đơn",
    date: d(2026, 4, 1),
    note: "Phòng trọ Q.Bình Thạnh",
    image: true,
  );
  await add(
    title: "Học tiếng Anh",
    amount: 2500000,
    isIncome: false,
    category: "Công việc",
    date: d(2026, 4, 3),
    note: "ILA tháng 4 – quyết tâm học đều hơn",
    audio: true,
  );
  await add(
    title: "Lương tháng 4",
    amount: 45000000,
    isIncome: true,
    category: "Lương",
    date: d(2026, 4, 5),
  );
  await add(
    title: "Tạp hoá (ăn nhà nhiều hơn)",
    amount: 480000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 4, 6),
    note: "Mua nguyên liệu nấu ăn cả tuần",
  );
  await add(
    title: "Cà phê sáng",
    amount: 50000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 4, 7),
    note: "Cắt bớt xuống 1-2 lần/tuần",
  );
  await add(
    title: "Tiền điện nước & internet",
    amount: 750000,
    isIncome: false,
    category: "Hoá đơn",
    date: d(2026, 4, 8),
    image: true,
  );
  await add(
    title: "Cơm trưa bình dân",
    amount: 50000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 4, 9),
  );
  await add(
    title: "Grab đi làm",
    amount: 95000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 4, 10),
  );
  await add(
    title: "Cà phê",
    amount: 55000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 4, 12),
  );
  await add(
    title: "Tạp hoá",
    amount: 350000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 4, 12),
  );
  await add(
    title: "Cơm trưa",
    amount: 50000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 4, 13),
  );
  await add(
    title: "Ăn tối cuối tuần (tự thưởng)",
    amount: 150000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 4, 14),
    note: "Cơm tấm sườn – đơn giản thôi",
  );
  await add(
    title: "Grab",
    amount: 90000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 4, 15),
  );
  await add(
    title: "Tạp hoá cuối tuần",
    amount: 420000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 4, 16),
    note: "Mua đủ rau thịt để nấu cả tuần sau",
  );
  await add(
    title: "Cà phê sáng",
    amount: 50000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 4, 17),
  );
  await add(
    title: "Cơm trưa",
    amount: 50000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 4, 19),
  );
  await add(
    title: "Cà phê",
    amount: 55000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 4, 20),
  );
  await add(
    title: "Grab đi làm",
    amount: 90000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 4, 21),
  );
  await add(
    title: "Tạp hoá",
    amount: 380000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 4, 22),
  );
  await add(
    title: "Cơm trưa",
    amount: 50000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 4, 23),
  );
  await add(
    title: "Sách self-improvement",
    amount: 180000,
    isIncome: false,
    category: "Công việc",
    date: d(2026, 4, 24),
    note: "Atomic Habits – đọc để thay đổi thói quen",
  );
  await add(
    title: "Cà phê",
    amount: 50000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 4, 25),
  );
  await add(
    title: "Ăn tối cuối tuần",
    amount: 160000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 4, 26),
  );
  await add(
    title: "Tạp hoá",
    amount: 350000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 4, 27),
  );
  await add(
    title: "Grab",
    amount: 90000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 4, 28),
  );
  await add(
    title: "Cà phê",
    amount: 50000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 4, 29),
  );
  await add(
    title: "Cơm trưa",
    amount: 50000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 4, 30),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // MAY 2026 (days mapped to recent days relative to today)
  // ══════════════════════════════════════════════════════════════════════════
  await add(
    title: "Thuê nhà tháng 5",
    amount: 9000000,
    isIncome: false,
    category: "Hoá đơn",
    date: d(2026, 5, 1),
    note: "Phòng trọ Q.Bình Thạnh",
    image: true,
  );
  await add(
    title: "Học tiếng Anh",
    amount: 2500000,
    isIncome: false,
    category: "Công việc",
    date: d(2026, 5, 2),
    note: "ILA tháng 5",
    audio: true,
  );
  await add(
    title: "Tạp hoá đầu tháng",
    amount: 450000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 5, 3),
  );
  await add(
    title: "Lương tháng 5",
    amount: 45000000,
    isIncome: true,
    category: "Lương",
    date: d(2026, 5, 5),
  );
  await add(
    title: "Cà phê sáng",
    amount: 50000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 5, 5),
  );
  await add(
    title: "Cơm trưa bình dân",
    amount: 50000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 5, 6),
  );
  await add(
    title: "Grab đi làm",
    amount: 90000,
    isIncome: false,
    category: "Di chuyển",
    date: d(2026, 5, 7),
  );
  await add(
    title: "Tạp hoá",
    amount: 380000,
    isIncome: false,
    category: "Tạp hoá",
    date: d(2026, 5, 8),
  );
  await add(
    title: "Cà phê",
    amount: 50000,
    isIncome: false,
    category: "Cà phê",
    date: d(2026, 5, 9),
  );
  await add(
    title: "Cơm trưa",
    amount: 50000,
    isIncome: false,
    category: "Ăn uống",
    date: d(2026, 5, 10),
  );

  // ══════════════════════════════════════════════════════════════════════════
  // 10 PENDING TRANSACTIONS — recent days, chờ đối soát
  // ══════════════════════════════════════════════════════════════════════════

  // 3 audio recordings (no amount → incomplete → only "Cập nhật")
  await addPending(
    title: "Ghi âm giao dịch ${_ts(recent(0))}",
    amount: 0,
    category: "Ăn uống",
    isIncome: false,
    date: recent(0),
    audio: true,
    note: "Ghi chú chi tiêu hôm nay",
  );
  await addPending(
    title: "Ghi âm giao dịch ${_ts(recent(3))}",
    amount: 0,
    category: "Di chuyển",
    isIncome: false,
    date: recent(3),
    audio: true,
  );
  await addPending(
    title: "Ghi âm giao dịch ${_ts(recent(6))}",
    amount: 0,
    category: "Cà phê",
    isIncome: false,
    date: recent(6),
    audio: true,
    note: "Cần xác nhận số tiền",
  );

  // 3 bill images (some with amount → complete → shows "Xác nhận" + "Cập nhật")
  await addPending(
    title: "Ảnh hoá đơn ${_ts(recent(1))}",
    amount: 320000,
    category: "Tạp hoá",
    isIncome: false,
    date: recent(1),
    image: true,
    note: "Siêu thị Vinmart",
  );
  await addPending(
    title: "Ảnh hoá đơn ${_ts(recent(4))}",
    amount: 185000,
    category: "Ăn uống",
    isIncome: false,
    date: recent(4),
    image: true,
  );
  await addPending(
    title: "Ảnh hoá đơn ${_ts(recent(8))}",
    amount: 0,
    category: "Sức khoẻ",
    isIncome: false,
    date: recent(8),
    image: true,
    note: "Hoá đơn bệnh viện – chưa xác nhận số tiền",
  );

  // 4 quick entries (mix of complete / incomplete)
  await addPending(
    title: "Grab đi làm",
    amount: 95000,
    category: "Di chuyển",
    isIncome: false,
    date: recent(2),
    image: true,
    note: "Cần xác nhận lại",
  );
  await addPending(
    title: "Cà phê buổi sáng",
    amount: 65000,
    category: "Cà phê",
    isIncome: false,
    date: recent(5),
    image: true,
  );
  await addPending(
    title: "Mua sắm",
    amount: 0,
    category: "Mua sắm",
    isIncome: false,
    date: recent(7),
    audio: true,
    note: "Chưa nhớ số tiền",
  );
  await addPending(
    title: "Chi phí khác",
    amount: 0,
    category: "Khác",
    isIncome: false,
    date: recent(9),
    audio: true,
    note: "Cần bổ sung thông tin",
  );
}

/// Format timestamp for media transaction titles.
String _ts(DateTime dt) {
  final m = dt.month.toString().padLeft(2, "0");
  final d = dt.day.toString().padLeft(2, "0");
  final h = dt.hour.toString().padLeft(2, "0");
  final min = dt.minute.toString().padLeft(2, "0");
  return "$d/$m $h:$min";
}

Future<({int width, int height})> _imageSize(Uint8List bytes) async {
  final codec = await ui.instantiateImageCodec(bytes);
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final size = (width: image.width, height: image.height);
  image.dispose();
  codec.dispose();
  return size;
}
