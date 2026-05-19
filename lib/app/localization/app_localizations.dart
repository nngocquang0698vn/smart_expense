import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";

class AppLocalizations {
  const AppLocalizations(this.locale, this._strings);

  static const vi = AppLocalizations(Locale("vi", "VN"), _vi);

  final Locale locale;
  final Map<String, String> _strings;

  static const supportedLocales = [Locale("vi", "VN")];

  static const localizationsDelegates = [
    _AppLocalizationsDelegate(),
    ...GlobalMaterialLocalizations.delegates,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ?? vi;
  }

  String text(String key) => _strings[key] ?? _vi[key] ?? key;

  String get addCategory => text("addCategory");
  String get addTransaction => text("addTransaction");
  String get accentColorsSubtitle => text("accentColorsSubtitle");
  String get accentColorsTitle => text("accentColorsTitle");
  String get amount => text("amount");
  String get amountRequired => text("amountRequired");
  String get apply => text("apply");
  String get appearanceTitle => text("appearanceTitle");
  String get appName => text("appName");
  String get back => text("back");
  String get cancel => text("cancel");
  String get category => text("category");
  String get categoryColor => text("categoryColor");
  String get categoryDefault => text("categoryDefault");
  String get categoryDisabled => text("categoryDisabled");
  String get categoryIcon => text("categoryIcon");
  String get categoryInUseDeleteDenied => text("categoryInUseDeleteDenied");
  String get categoryName => text("categoryName");
  String get categoryNameRequired => text("categoryNameRequired");
  String get categoryNoun => text("categoryNoun");
  String get categoryRequired => text("categoryRequired");
  String get categorySubtitle => text("categorySubtitle");
  String get categorySystemDeleteDenied => text("categorySystemDeleteDenied");
  String get close => text("close");
  String get confirm => text("confirm");
  String get confirmPendingMessage => text("confirmPendingMessage");
  String get confirmPendingTitle => text("confirmPendingTitle");
  String get continueEditing => text("continueEditing");
  String get continueEntry => text("continueEntry");
  String get customizationTitle => text("customizationTitle");
  String get darkModeSubtitle => text("darkModeSubtitle");
  String get darkModeTitle => text("darkModeTitle");
  String get dateFilterCustomRange => text("dateFilterCustomRange");
  String get dateFilterCustom => text("dateFilterCustom");
  String get dateFilterLast30Days => text("dateFilterLast30Days");
  String dateFilterMonthValue(int month, int year) => text(
    "dateFilterMonthValue",
  ).replaceAll("{month}", "$month").replaceAll("{year}", "$year");
  String get dateFilterAllTime => text("dateFilterAllTime");
  String get dateFilterPickMonth => text("dateFilterPickMonth");
  String get dateFilterPickYear => text("dateFilterPickYear");
  String get dateFilterThisMonth => text("dateFilterThisMonth");
  String get dateFilterThisWeek => text("dateFilterThisWeek");
  String get dateFilterThisYear => text("dateFilterThisYear");
  String get dateFilterTitle => text("dateFilterTitle");
  String dateFilterYearValue(int year) =>
      text("dateFilterYearValue").replaceAll("{year}", "$year");
  String get datePickerNotSelected => text("datePickerNotSelected");
  String get dateRangeClear => text("dateRangeClear");
  String get dateRangeNotSelected => text("dateRangeNotSelected");
  String get dateRangeTitle => text("dateRangeTitle");
  String get delete => text("delete");
  String get deleteCategoryTitle => text("deleteCategoryTitle");
  String get deleteTransaction => text("deleteTransaction");
  String get deleteTransactionMessage => text("deleteTransactionMessage");
  String get deleteTransactionTitle => text("deleteTransactionTitle");
  String get deleteVoiceNote => text("deleteVoiceNote");
  String get deleteVoiceNoteMessage => text("deleteVoiceNoteMessage");
  String get deleteVoiceNoteTitle => text("deleteVoiceNoteTitle");
  String get demoDataMessage => text("demoDataMessage");
  String get demoDataTitle => text("demoDataTitle");
  String get demoDataConfirm => text("demoDataConfirm");
  String get demoDataLoaded => text("demoDataLoaded");
  String get demoDataLoading => text("demoDataLoading");
  String get demoModeButton => text("demoModeButton");
  String get demoPersonName => text("demoPersonName");
  String get demoPersonSummary => text("demoPersonSummary");
  String get demoSectionTitle => text("demoSectionTitle");
  String get defaultGreenPreset => text("defaultGreenPreset");
  String get discard => text("discard");
  String get discardEditMessage => text("discardEditMessage");
  String get discardEditTitle => text("discardEditTitle");
  String get discardEntryMessage => text("discardEntryMessage");
  String get discardEntryTitle => text("discardEntryTitle");
  String get editCategory => text("editCategory");
  String get editTransaction => text("editTransaction");
  String get expense => text("expense");
  String get genericError => text("genericError");
  String get historyTitle => text("historyTitle");
  String get homeTitle => text("homeTitle");
  String get imageSaveFailed => text("imageSaveFailed");
  String get income => text("income");
  String get keepVoiceNote => text("keepVoiceNote");
  String get loading => text("loading");
  String get navAnalytics => text("navAnalytics");
  String get navHome => text("navHome");
  String get navPending => text("navPending");
  String get navProfile => text("navProfile");
  String get nameSaved => text("nameSaved");
  String get newCategory => text("newCategory");
  String get noCategories => text("noCategories");
  String get noDataForFilter => text("noDataForFilter");
  String get noDataForPeriod => text("noDataForPeriod");
  String get noPending => text("noPending");
  String get noPendingShort => text("noPendingShort");
  String get note => text("note");
  String get noteOptional => text("noteOptional");
  String get noTransactions => text("noTransactions");
  String get onboardingBack => text("onboardingBack");
  String get onboardingFastBody => text("onboardingFastBody");
  String get onboardingFastTitle => text("onboardingFastTitle");
  String get onboardingInsightsBody => text("onboardingInsightsBody");
  String get onboardingInsightsTitle => text("onboardingInsightsTitle");
  String get onboardingIntroBody => text("onboardingIntroBody");
  String get onboardingIntroTitle => text("onboardingIntroTitle");
  String get onboardingNameHint => text("onboardingNameHint");
  String get onboardingNameLabel => text("onboardingNameLabel");
  String get onboardingNameRequired => text("onboardingNameRequired");
  String get onboardingNext => text("onboardingNext");
  String get onboardingPrevious => text("onboardingPrevious");
  String get onboardingReviewBody => text("onboardingReviewBody");
  String get onboardingReviewTitle => text("onboardingReviewTitle");
  String get onboardingSkip => text("onboardingSkip");
  String get onboardingStart => text("onboardingStart");
  String get otherCategory => text("otherCategory");
  String get pausePlayback => text("pausePlayback");
  String get pending => text("pending");
  String get pendingTransactionsSubtitle => text("pendingTransactionsSubtitle");
  String get pendingTransactionsTitle => text("pendingTransactionsTitle");
  String get pendingSubtitleDefault => text("pendingSubtitleDefault");
  String get pendingSubtitleWithMedia => text("pendingSubtitleWithMedia");
  String get pickPhoto => text("pickPhoto");
  String get pickYearTitle => text("pickYearTitle");
  String get playBack => text("playBack");
  String get profileTitle => text("profileTitle");
  String get pwaInstallAndroidStep1 => text("pwaInstallAndroidStep1");
  String get pwaInstallAndroidStep2 => text("pwaInstallAndroidStep2");
  String get pwaInstallAndroidStep3 => text("pwaInstallAndroidStep3");
  String get pwaInstallDesktopStep1 => text("pwaInstallDesktopStep1");
  String get pwaInstallDesktopStep2 => text("pwaInstallDesktopStep2");
  String get pwaInstallDesktopStep3 => text("pwaInstallDesktopStep3");
  String get pwaInstallGuideTitle => text("pwaInstallGuideTitle");
  String get pwaInstallIosStep1 => text("pwaInstallIosStep1");
  String get pwaInstallIosStep2 => text("pwaInstallIosStep2");
  String get pwaInstallIosStep3 => text("pwaInstallIosStep3");
  String get pwaInstallLater => text("pwaInstallLater");
  String get pwaInstallMenuItem => text("pwaInstallMenuItem");
  String get pwaInstallMenuSubtitle => text("pwaInstallMenuSubtitle");
  String get pwaInstallNever => text("pwaInstallNever");
  String get pwaInstallNow => text("pwaInstallNow");
  String get pwaInstallSubtitle => text("pwaInstallSubtitle");
  String get pwaInstallTitle => text("pwaInstallTitle");
  String get quickEntryReceipt => text("quickEntryReceipt");
  String get quickEntryReceiptCaptureSubtitle =>
      text("quickEntryReceiptCaptureSubtitle");
  String get quickEntryReceiptCaptureTitle =>
      text("quickEntryReceiptCaptureTitle");
  String get quickEntryReceiptPickSubtitle =>
      text("quickEntryReceiptPickSubtitle");
  String get quickEntryReceiptPickTitle => text("quickEntryReceiptPickTitle");
  String get quickEntryTap => text("quickEntryTap");
  String get quickEntryTapSubtitle => text("quickEntryTapSubtitle");
  String get quickEntryVoice => text("quickEntryVoice");
  String get quickEntryVoiceSubtitle => text("quickEntryVoiceSubtitle");
  String get quickTransactionTitle => text("quickTransactionTitle");
  String get quickExpenseTitle => text("quickExpenseTitle");
  String get quickIncomeTitle => text("quickIncomeTitle");
  String get readyToRecord => text("readyToRecord");
  String get record => text("record");
  String get recording => text("recording");
  String get recordSuccess => text("recordSuccess");
  String get reportBalance => text("reportBalance");
  String get reportByCategory => text("reportByCategory");
  String get reportPeriodCustom => text("reportPeriodCustom");
  String get reportPeriodMonth => text("reportPeriodMonth");
  String get reportPeriodQuarter => text("reportPeriodQuarter");
  String get reportPeriodWeek => text("reportPeriodWeek");
  String get reportPeriodYear => text("reportPeriodYear");
  String get reportTitle => text("reportTitle");
  String get reRecord => text("reRecord");
  String get resumePlayback => text("resumePlayback");
  String get retry => text("retry");
  String get save => text("save");
  String get savePendingSuccess => text("savePendingSuccess");
  String get saveTransaction => text("saveTransaction");
  String get saveTransactionSuccess => text("saveTransactionSuccess");
  String get seeAll => text("seeAll");
  String get seedColorLabel => text("seedColorLabel");
  String get startRecording => text("startRecording");
  String get stopRecording => text("stopRecording");
  String get takePhoto => text("takePhoto");
  String get titleOptional => text("titleOptional");
  String get titleRequired => text("titleRequired");
  String get transactionDate => text("transactionDate");
  String get transactionNoun => text("transactionNoun");
  String get transactionTitle => text("transactionTitle");
  String get update => text("update");
  String get userNameLabel => text("userNameLabel");
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => locale.languageCode == "vi";

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations.vi);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

const _vi = {
  "accentColorsSubtitle":
      "Chọn thêm màu chủ đạo thay cho ngọc lục bảo mặc định",
  "accentColorsTitle": "Màu sắc khác",
  "appearanceTitle": "Giao diện",
  "categoryNoun": "hạng mục",
  "categorySubtitle": "Thêm, sửa, xoá hạng mục thu chi",
  "customizationTitle": "Tuỳ chỉnh",
  "darkModeSubtitle": "Giao diện tối, dễ nhìn ban đêm",
  "darkModeTitle": "Chế độ tối",
  "demoDataConfirm": "Nạp dữ liệu",
  "demoDataLoaded": "Đã nạp xong dữ liệu Johny Nguyễn!",
  "demoDataLoading": "Đang nạp dữ liệu...",
  "demoModeButton": "Chuyển qua chế độ demo",
  "demoPersonName": "Nhân vật Johny Nguyễn",
  "demoPersonSummary": "Software Engineer · TP.HCM · 45tr/tháng",
  "demoSectionTitle": "Dữ liệu demo",
  "defaultGreenPreset": "Ngọc lục bảo (mặc định)",
  "nameSaved": "Đã lưu tên",
  "pendingTransactionsSubtitle": "Mở danh sách đối soát",
  "pendingTransactionsTitle": "Giao dịch chờ đối soát",
  "profileTitle": "Cá nhân",
  "quickEntryReceiptCaptureSubtitle": "Lưu ảnh hoá đơn để đối soát sau",
  "quickEntryReceiptCaptureTitle": "Chụp ảnh hoá đơn",
  "quickEntryReceiptPickSubtitle": "Chọn ảnh từ máy để lưu hoá đơn đối soát",
  "quickEntryReceiptPickTitle": "Chọn ảnh hoá đơn",
  "quickEntryTapSubtitle": "Nhập liệu cực nhanh với một lần chạm",
  "quickEntryVoiceSubtitle": "Ghi nhanh một bản ghi âm để đối soát sau",
  "quickTransactionTitle": "Thêm giao dịch nhanh",
  "seedColorLabel": "Màu chủ đạo",
  "userNameLabel": "Tên người dùng",
  "addCategory": "Thêm hạng mục",
  "addTransaction": "Thêm giao dịch",
  "amount": "Số tiền (VND)",
  "amountRequired": "Vui lòng nhập số tiền hợp lệ.",
  "apply": "Áp dụng",
  "back": "Quay lại",
  "cancel": "Huỷ",
  "category": "Hạng mục",
  "categoryColor": "Màu sắc",
  "categoryDefault": "Hạng mục mặc định",
  "categoryDisabled": "Đã tắt",
  "categoryIcon": "Biểu tượng",
  "categoryInUseDeleteDenied":
      "Không xoá được: còn giao dịch dùng hạng mục này.",
  "categoryName": "Tên hạng mục",
  "categoryNameRequired": "Vui lòng nhập tên hạng mục.",
  "categoryRequired": "Vui lòng chọn hạng mục.",
  "categorySystemDeleteDenied": "Không thể xoá hạng mục mặc định.",
  "close": "Đóng",
  "confirm": "Xác nhận",
  "confirmPendingMessage":
      "Giao dịch này sẽ được chuyển khỏi danh sách chờ đối soát.",
  "confirmPendingTitle": "Xác nhận giao dịch?",
  "continueEditing": "Tiếp tục chỉnh sửa",
  "continueEntry": "Tiếp tục nhập",
  "dateFilterCustom": "Tuỳ chọn",
  "dateFilterCustomRange": "Khoảng ngày tuỳ chọn…",
  "dateFilterLast30Days": "30 ngày vừa qua",
  "dateFilterMonthValue": "Tháng {month}/{year}",
  "dateFilterAllTime": "Toàn bộ",
  "dateFilterPickMonth": "Theo tháng…",
  "dateFilterPickYear": "Theo năm…",
  "dateFilterThisMonth": "Tháng này",
  "dateFilterThisWeek": "Tuần này",
  "dateFilterThisYear": "Năm này",
  "dateFilterTitle": "Bộ lọc thời gian",
  "dateFilterYearValue": "Năm {year}",
  "datePickerNotSelected": "Chưa chọn ngày",
  "dateRangeClear": "Xóa",
  "dateRangeNotSelected": "Chưa chọn khoảng ngày",
  "dateRangeTitle": "Chọn khoảng ngày",
  "delete": "Xoá",
  "deleteCategoryTitle": "Xoá hạng mục?",
  "deleteTransaction": "Xoá giao dịch",
  "deleteTransactionMessage": "Hành động này không thể hoàn tác.",
  "deleteTransactionTitle": "Xoá giao dịch?",
  "deleteVoiceNote": "Xoá ghi âm",
  "deleteVoiceNoteMessage": "Bản ghi này sẽ bị xoá khỏi giao dịch hiện tại.",
  "deleteVoiceNoteTitle": "Xoá ghi âm?",
  "demoDataMessage":
      "Thao tác này sẽ xoá toàn bộ giao dịch hiện tại và thay bằng dữ liệu demo.",
  "demoDataTitle": "Nạp dữ liệu demo?",
  "discard": "Huỷ thay đổi",
  "discardEditMessage":
      "Mọi thay đổi chưa lưu sẽ bị mất. Bạn có chắc chắn muốn đóng không?",
  "discardEditTitle": "Huỷ thay đổi?",
  "discardEntryMessage":
      "Mọi thay đổi chưa lưu sẽ bị mất. Bạn có chắc chắn muốn đóng không?",
  "discardEntryTitle": "Huỷ nhập liệu?",
  "editCategory": "Chỉnh sửa hạng mục",
  "editTransaction": "Sửa giao dịch",
  "genericError": "Đã có lỗi xảy ra. Vui lòng thử lại.",
  "imageSaveFailed": "Không thể lưu ảnh. Vui lòng thử lại.",
  "keepVoiceNote": "Giữ lại",
  "newCategory": "Hạng mục mới",
  "noCategories": "Chưa có hạng mục nào.",
  "noDataForFilter": "Chưa có giao dịch trong khoảng lọc.",
  "noDataForPeriod": "Chưa có dữ liệu cho kỳ này.",
  "noPending": "Không có giao dịch chờ.",
  "noPendingShort": "Không có giao dịch chờ",
  "note": "Ghi chú",
  "noteOptional": "Ghi chú (tuỳ chọn)",
  "noTransactions": "Chưa có giao dịch nào.",
  "otherCategory": "Khác",
  "pausePlayback": "Tạm dừng",
  "pendingSubtitleDefault": "Bật để chuyển vào danh sách đối soát.",
  "pendingSubtitleWithMedia": "Có audio/ảnh — nên bật để đối soát sau.",
  "pickPhoto": "Chọn ảnh",
  "pickYearTitle": "Chọn năm",
  "playBack": "Nghe lại",
  "pwaInstallAndroidStep1": "Nhấn menu ⋮ ở góc trên bên phải",
  "pwaInstallAndroidStep2":
      "Chọn \"Cài đặt ứng dụng\" hoặc \"Thêm vào màn hình chính\"",
  "pwaInstallAndroidStep3": "Xác nhận để thêm biểu tượng lên màn hình chính",
  "pwaInstallDesktopStep1":
      "Nhấn biểu tượng cài đặt trên thanh địa chỉ (hoặc menu trình duyệt)",
  "pwaInstallDesktopStep2":
      "Chọn \"Cài đặt Smart Expense\" hoặc \"Install app\"",
  "pwaInstallDesktopStep3": "Mở ứng dụng từ shortcut trên máy tính",
  "pwaInstallGuideTitle": "Cách cài ứng dụng",
  "pwaInstallIosStep1": "Nhấn nút Chia sẻ (hình vuông có mũi tên)",
  "pwaInstallIosStep2": "Chọn \"Thêm vào Màn hình chính\"",
  "pwaInstallIosStep3": "Nhấn \"Thêm\" để hoàn tất",
  "pwaInstallLater": "Để sau",
  "pwaInstallMenuItem": "Cài app lên màn hình chính",
  "pwaInstallMenuSubtitle": "Xem hướng dẫn thêm vào màn hình chính",
  "pwaInstallNever": "Không nhắc lại",
  "pwaInstallNow": "Cài đặt ngay",
  "pwaInstallSubtitle":
      "Truy cập nhanh hơn như một ứng dụng. Dữ liệu vẫn được lưu cục bộ trên thiết bị của bạn.",
  "pwaInstallTitle": "Cài Smart Expense lên màn hình chính",
  "quickEntryReceipt": "Ảnh hoá đơn",
  "quickEntryTap": "Nhập nhanh",
  "quickEntryVoice": "Ghi âm giao dịch",
  "quickExpenseTitle": "Chi tiêu nhanh",
  "quickIncomeTitle": "Thu nhập nhanh",
  "readyToRecord": "Sẵn sàng ghi âm",
  "record": "Ghi âm",
  "recording": "Đang ghi âm...",
  "recordSuccess": "Ghi âm thành công",
  "reportBalance": "Còn lại",
  "reportByCategory": "Theo hạng mục",
  "reportPeriodCustom": "Tuỳ chọn",
  "reportPeriodMonth": "Tháng",
  "reportPeriodQuarter": "Quý",
  "reportPeriodWeek": "Tuần",
  "reportPeriodYear": "Năm",
  "reportTitle": "Báo cáo",
  "reRecord": "Ghi lại",
  "resumePlayback": "Tiếp tục phát",
  "retry": "Thử lại",
  "save": "Lưu",
  "savePendingSuccess": "Đã lưu vào danh sách chờ đối soát.",
  "saveTransaction": "Lưu giao dịch",
  "saveTransactionSuccess": "Đã lưu giao dịch.",
  "startRecording": "Bắt đầu",
  "stopRecording": "Dừng",
  "takePhoto": "Chụp ảnh",
  "titleOptional": "Tiêu đề (tuỳ chọn)",
  "titleRequired": "Vui lòng nhập tên giao dịch.",
  "transactionDate": "Ngày giao dịch",
  "transactionNoun": "giao dịch",
  "transactionTitle": "Tên giao dịch",
  "update": "Cập nhật",
  "appName": "Smart Ledger",
  "loading": "Đang tải dữ liệu...",
  "navHome": "Trang chủ",
  "navPending": "Đối soát",
  "navAnalytics": "Báo cáo",
  "navProfile": "Cá nhân",
  "homeTitle": "Trang chủ",
  "income": "Thu nhập",
  "expense": "Chi tiêu",
  "pending": "Chờ đối soát",
  "seeAll": "Xem tất cả",
  "historyTitle": "Lịch sử giao dịch",
  "onboardingNameRequired": "Vui lòng nhập tên của bạn",
  "onboardingSkip": "Bỏ qua",
  "onboardingBack": "Quay lại",
  "onboardingStart": "Bắt đầu",
  "onboardingPrevious": "Trước",
  "onboardingNext": "Tiếp theo",
  "onboardingNameLabel": "Nhập tên của bạn?",
  "onboardingNameHint": "Ví dụ: Nguyễn Văn A",
  "onboardingIntroTitle": "Smart Ledger",
  "onboardingIntroBody":
      "Ghi chép thu chi thông minh - lưu trữ ngay trên thiết bị - không cần kết nối mạng.",
  "onboardingFastTitle": "Ghi chép siêu tốc",
  "onboardingFastBody":
      "Chạm để nhập nhanh, chụp ảnh hoá đơn hoặc ghi âm giọng nói - tất cả trong vài giây.",
  "onboardingReviewTitle": "Đối soát thông minh",
  "onboardingReviewBody":
      "Xem lại và phân loại giao dịch chờ bất cứ lúc nào, khi bạn có thời gian rảnh.",
  "onboardingInsightsTitle": "Quản lý thông minh",
  "onboardingInsightsBody":
      "Theo dõi thu chi qua biểu đồ trực quan - toàn bộ dữ liệu lưu riêng tư trên máy bạn.",
};
