/// Central registry of all user-facing strings in the app.
///
/// **Scope:** Only strings that appear in ≥ 3 places OR carry domain
/// terminology that may need renaming. One-off long paragraphs (dialog bodies,
/// onboarding copy, validation messages specific to a single screen) stay
/// inline where they are authored — extracting them here would only add
/// indirection without reducing duplication.
///
/// **i18n note:** This app is Vietnamese-only. If multi-language support is
/// needed in the future, replace this file with Flutter gen_l10n ARB files and
/// run `flutter gen-l10n`.
abstract final class AppStrings {
  static const String appName = "Smart Ledger";
  static const String genericError = "Đã có lỗi xảy ra. Vui lòng thử lại.";
  static const String loading = "Đang tải dữ liệu...";
  static const String imageSaveFailed = "Không thể lưu ảnh. Vui lòng thử lại.";
  static const String delete = "Xoá";
  static const String discard = "Huỷ thay đổi";
  static const String continueEditing = "Tiếp tục chỉnh sửa";
  static const String discardEntryTitle = "Huỷ nhập liệu?";
  static const String discardEntryMessage =
      "Mọi thay đổi chưa lưu sẽ bị mất. Bạn có chắc chắn muốn đóng không?";
  static const String continueEntry = "Tiếp tục nhập";
  static const String discardEditTitle = "Huỷ thay đổi?";
  static const String discardEditMessage =
      "Mọi thay đổi chưa lưu sẽ bị mất. Bạn có chắc chắn muốn đóng không?";
  static const String deleteVoiceNoteTitle = "Xoá ghi âm?";
  static const String deleteVoiceNoteMessage =
      "Bản ghi này sẽ bị xoá khỏi giao dịch hiện tại.";
  static const String keepVoiceNote = "Giữ lại";
  static const String deleteVoiceNote = "Xoá ghi âm";
  static const String confirmPendingTitle = "Xác nhận giao dịch?";
  static const String confirmPendingMessage =
      "Giao dịch này sẽ được chuyển khỏi danh sách chờ đối soát.";
  static const String deleteTransactionTitle = "Xoá giao dịch?";
  static const String deleteTransactionMessage =
      "Hành động này không thể hoàn tác.";
  static const String deleteCategoryTitle = "Xoá hạng mục?";
  static const String addCategory = "Thêm hạng mục";
  static const String editCategory = "Chỉnh sửa hạng mục";
  static const String newCategory = "Hạng mục mới";
  static const String categoryName = "Tên hạng mục";
  static const String categoryColor = "Màu sắc";
  static const String categoryIcon = "Biểu tượng";
  static const String categoryDefault = "Hạng mục mặc định";
  static const String categoryDisabled = "Đã tắt";
  static const String categoryNameRequired = "Vui lòng nhập tên hạng mục.";
  static const String categorySystemDeleteDenied =
      "Không thể xoá hạng mục mặc định.";
  static const String categoryInUseDeleteDenied =
      "Không xoá được: còn giao dịch dùng hạng mục này.";
  static const String demoDataTitle = "Nạp dữ liệu demo?";
  static const String demoDataMessage =
      "Thao tác này sẽ xoá toàn bộ giao dịch hiện tại và thay bằng dữ liệu demo.";
  // ── Navigation labels (main_shell + pill_nav_bar) ─────────────────────────

  static const String navHome = "Trang chủ";
  static const String navPending = "Đối soát";
  static const String navAnalytics = "Báo cáo";
  static const String navProfile = "Cá nhân";

  // ── Domain terms ──────────────────────────────────────────────────────────

  static const String expense = "Chi tiêu";
  static const String income = "Thu nhập";

  /// The reconciliation queue — appears in headers, badges, buttons, dialogs.
  static const String pending = "Chờ đối soát";

  /// Fallback category name when a category is disabled.
  static const String otherCategory = "Khác";

  static const String category = "Hạng mục";
  static const String note = "Ghi chú";
  static const String noteOptional = "Ghi chú (tuỳ chọn)";
  static const String titleOptional = "Tiêu đề (tuỳ chọn)";
  static const String quickEntryTap = "Nhập nhanh";
  static const String quickEntryVoice = "Ghi âm giao dịch";
  static const String quickEntryReceipt = "Ảnh hoá đơn";
  static const String pendingSubtitleWithMedia =
      "Có audio/ảnh — nên bật để đối soát sau.";
  static const String pendingSubtitleDefault =
      "Bật để chuyển vào danh sách đối soát.";
  static const String transactionDate = "Ngày giao dịch";
  static const String transactionTitle = "Tên giao dịch";
  static const String amount = "Số tiền (VND)";

  /// Singular noun used in count labels, e.g. "3 giao dịch chờ".
  static const String transactionNoun = "giao dịch";

  static const String historyTitle = "Lịch sử giao dịch";
  static const String reportTitle = "Báo cáo";
  static const String reportBalance = "Còn lại";
  static const String reportByCategory = "Theo hạng mục";

  // ── Common action labels ──────────────────────────────────────────────────

  static const String confirm = "Xác nhận";
  static const String update = "Cập nhật";
  static const String cancel = "Huỷ";
  static const String save = "Lưu";
  static const String close = "Đóng";
  static const String apply = "Áp dụng";
  static const String retry = "Thử lại";
  static const String seeAll = "Xem tất cả";
  static const String back = "Quay lại";

  // ── Transaction-entry actions ─────────────────────────────────────────────

  static const String saveTransaction = "Lưu giao dịch";
  static const String deleteTransaction = "Xoá giao dịch";
  static const String addTransaction = "Thêm giao dịch";
  static const String editTransaction = "Sửa giao dịch";
  static const String quickExpenseTitle = "Chi tiêu nhanh";
  static const String quickIncomeTitle = "Thu nhập nhanh";
  static const String savePendingSuccess = "Đã lưu vào danh sách chờ đối soát.";
  static const String saveTransactionSuccess = "Đã lưu giao dịch.";
  static const String amountRequired = "Vui lòng nhập số tiền hợp lệ.";
  static const String categoryRequired = "Vui lòng chọn danh mục.";
  static const String titleRequired = "Vui lòng nhập tên giao dịch.";

  // ── Media / recording ─────────────────────────────────────────────────────

  static const String record = "Ghi âm";
  static const String takePhoto = "Chụp ảnh";
  static const String pickPhoto = "Chọn ảnh";
  static const String stopRecording = "Dừng";
  static const String startRecording = "Bắt đầu";
  static const String reRecord = "Ghi lại";
  static const String playBack = "Nghe lại";
  static const String pausePlayback = "Tạm dừng";
  static const String resumePlayback = "Tiếp tục phát";
  static const String recording = "Đang ghi âm...";
  static const String recordSuccess = "Ghi âm thành công";
  static const String readyToRecord = "Sẵn sàng ghi âm";

  // ── Empty / loading states ────────────────────────────────────────────────

  static const String noPending = "Không có giao dịch chờ.";
  static const String noPendingShort = "Không có giao dịch chờ";
  static const String noCategories = "Chưa có hạng mục nào.";
  static const String noDataForFilter = "Chưa có giao dịch trong khoảng lọc.";
  static const String noDataForPeriod = "Chưa có dữ liệu cho kỳ này.";
  static const String noTransactions = "Chưa có giao dịch nào.";
}
