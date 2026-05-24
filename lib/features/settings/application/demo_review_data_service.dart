import "package:smart_expense/core/seed/seed_attachments.dart";
import "package:smart_expense/features/categories/application/category_selection_resolver.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

class DemoReviewDataService {
  const DemoReviewDataService(this._repo);

  static const titlePrefix = "[Demo đối soát]";

  final LedgerRepository _repo;

  Future<void> seedPendingReviewTransactions() async {
    final categories = await _repo.categories();
    final lookup = CategoryNameLookup(categories);
    final expenseCategoryId =
        lookup.idFor(name: "Ăn uống", isIncome: false, fallbackName: "Khác") ??
        categories.firstWhere((category) => !category.isIncome).id;
    final media = await SeedAttachments.loadMeta();
    final now = DateTime.now();

    await _repo.addQuick(
      title: "$titlePrefix Ghi chú bữa tối",
      amountVnd: 128000,
      isIncome: false,
      categoryId: expenseCategoryId,
      at: now.subtract(const Duration(minutes: 12)),
      pending: true,
      complete: true,
      note:
          "Cần kiểm tra lại với ví điện tử. Giao dịch demo đang chờ xác nhận ghi chú.",
    );
    await _repo.addQuick(
      title: "$titlePrefix Ảnh hoá đơn",
      amountVnd: 245000,
      isIncome: false,
      categoryId: expenseCategoryId,
      at: now.subtract(const Duration(hours: 1)),
      pending: true,
      complete: true,
      images: [media.billImage()],
      note: "Có ảnh hoá đơn để người dùng đối chiếu.",
    );
    await _repo.addQuick(
      title: "$titlePrefix Ghi âm nhanh",
      amountVnd: 0,
      isIncome: false,
      categoryId: expenseCategoryId,
      at: now.subtract(const Duration(hours: 2)),
      pending: true,
      complete: false,
      audio: media.voiceNote(),
      note: "Có ghi âm mẫu, cần bổ sung số tiền.",
    );
    await _repo.addQuick(
      title: "$titlePrefix Không pending có media",
      amountVnd: 99000,
      isIncome: false,
      categoryId: expenseCategoryId,
      at: now.subtract(const Duration(hours: 3)),
      pending: false,
      complete: true,
      note:
          "Dòng này có metadata nhưng không được vào màn đối soát. Dùng để kiểm tra pending=false không lọt vào đối soát.",
      audio: media.voiceNote(),
      images: [media.billImage()],
    );
  }
}
