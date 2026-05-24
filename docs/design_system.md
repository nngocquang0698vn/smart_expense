# Design System

## Tổng quan

Smart Ledger dùng Material 3, tone xanh ngọc hiện đại, bo tròn mềm và layout responsive cho Web/PWA + Android. UI text hiện tập trung bằng tiếng Việt trong `AppLocalizations`.

## Token và theme

- Colors: `AppColors`.
- Spacing: `AppSpacing`, `AppInsets`.
- Radius: `AppRadius`.
- Typography: `AppTypography`.
- Breakpoints: `AppBreakpoints`.
- Theme builder: `AppTheme`.
- Theme extensions: `AppChromeTheme`, `AppLayoutTheme`, `AppFinanceColors`.
- Theme preferences: `ThemeSettings`, `ThemeController`.

## Component chính

- Transaction row: `TxRow`, `AppTransactionTile`.
- Form nhập giao dịch: `TransactionEntryForm`, `FormAmountField`, `TransactionNoteInput`.
- Attachment: `TransactionImageAttachments`, `ImageAttachmentPreviewDialog`, `VoiceRecorderInput`, `VoiceNotePlayer`.
- Pending: `PendingAttachmentFilterChips`, `PendingReconciliationDetailPanel`, `PendingEditorActionBar`.
- Report: `ReportPieChart`, `ReportCategoryRow`, `CategoryReportSummaryCard`.
- Feedback: `showSuccess`, `showInfo`, `showWarning`, `showError`.
- Empty/loading: `AppEmptyState`, `AppLoadingState`.
- Navigation: `PillNavBar`, desktop sidebar trong `MainShell`.

## Responsive rules

- Desktop từ `AppBreakpoints.desktop` dùng sidebar và master-detail ở Report/Pending.
- Mobile dùng bottom navigation và detail full-width.
- `IndexedStack` giữ state tab.
- List lớn dùng lazy builder/sliver/pagination.

## Profile UI hiện tại

Profile giữ cấu trúc gọn:

- Giao diện.
- Nhắc đối soát giao dịch.
- Cá nhân/danh mục/xác nhận nhanh/thêm nhanh/PWA install.
- Demo đối soát.
- Dữ liệu mẫu.

Demo đối soát hiển thị cả production để phục vụ trình diễn:

- Tạo giao dịch demo cần đối soát.
- Gửi thông báo sau 20 giây.
- Xoá tất cả dữ liệu.

Không có nút mở màn đối soát trong section demo; người dùng vẫn có entry Đối soát chính trong Profile và tab Đối soát.

## Settings UI

Section **Nhắc đối soát giao dịch** dùng:

- `SwitchListTile` cho bật/tắt.
- `SegmentedButton` cho mode Cuối ngày / Theo khoảng thời gian.
- Time picker cho giờ nhắc.
- Dropdown cho số tiếng lặp lại.
- Snackbar theo design system cho success/warning/info.

## Nguyên tắc khi thêm UI

- Dùng token/component sẵn có trước khi tạo component mới.
- Business logic không đặt trong `build`.
- Text mới nên thêm vào `AppLocalizations`.
- Không tự suy diễn pending từ attachment trong UI.
- Audio không autoplay; chỉ phát sau user gesture.
- Trạng thái empty/loading/error cần rõ ràng và dùng component hiện có.
