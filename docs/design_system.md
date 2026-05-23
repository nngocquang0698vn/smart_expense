# Design System

## Mục lục
- [Tổng quan style](#tổng-quan-style)
- [Token và theme](#token-và-theme)
- [Component chính](#component-chính)
- [Responsive rules](#responsive-rules)
- [Nguyên tắc UI](#nguyên-tắc-ui)
- [Ghi chú khi thêm UI mới](#ghi-chú-khi-thêm-ui-mới)

## Tổng quan style
Codebase hiện tại dùng Material 3, brand chính xanh ngọc, finance colors tách riêng cho thu/chi và các surface nhập liệu. UI text hiện tập trung bằng tiếng Việt trong `lib/app/localization/app_localizations.dart`.

## Token và theme
- Colors: `lib/shared/design_system/tokens/app_colors.dart`.
- Spacing: `AppSpacing` và `AppInsets`.
- Radius: `AppRadius`, nhiều card/sheet dùng radius 16-24.
- Typography: `AppTypography`, font family `Roboto`.
- Breakpoints: tablet `700`, desktop `1000`, wide `1280`.
- Theme builder: `lib/shared/design_system/theme/app_theme.dart`.
- Theme extensions: `AppChromeTheme`, `AppLayoutTheme`, `AppFinanceColors`.
- User theme settings: `lib/app/theme/theme_settings.dart`, lưu bằng SharedPreferences qua `ThemeController`.

## Component chính
- Transaction row/card:
  - `TxRow`: `lib/shared/components/tx_row.dart`.
  - `AppTransactionTile`: `lib/shared/components/app_transaction_tile.dart`.
- Report card/summary:
  - `SummaryCard`: `lib/shared/components/summary_card.dart`.
  - `CategoryReportSummaryCard`: `lib/features/reports/presentation/widgets/category_report_summary_card.dart`.
- Category item:
  - `_CategoryTile` trong `lib/features/categories/presentation/categories_screen.dart`.
  - `ReportCategoryRow` trong `lib/features/reports/presentation/widgets/report_category_row.dart`.
- Filter chips/date range:
  - `ReportPeriodChips`: report period.
  - `PendingAttachmentFilterChips`: pending attachment filter.
  - `showDateFilterSheet`: dashboard/pending date filter.
- Attachment UI:
  - `TransactionImageAttachments`, `ImageAttachmentList`, `ImageAttachmentPreviewDialog`.
  - `TransactionNoteInput`, `VoiceNotePlayer`, `VoiceRecorderInput`.
- Snackbar/notification:
  - `lib/shared/components/app_notification.dart`.
- Empty/loading/error:
  - `AppEmptyState`, `AppLoadingState`.
- Navigation:
  - `PillNavBar` mobile.
  - `_Sidebar` desktop trong `MainShell`.

## Responsive rules
- `MainShell` dùng `LayoutBuilder`; desktop width từ `AppBreakpoints.desktop` trở lên có sidebar, mobile có bottom pill nav.
- Page state được giữ bằng `IndexedStack` trong `lib/app/main_shell.dart`.
- Report desktop dùng master-detail: master bên trái, `CategoryReportDetailPanel` bên phải.
- Report mobile thay detail bằng body full-screen trong cùng `AnalyticsScreen` state.
- Pending desktop dùng master-detail: left list flex 4, right edit panel flex 6.
- Pending mobile hiển thị list; khi chọn transaction thì detail full-width với nút back.

## Nguyên tắc UI
- Text UI hướng tiếng Việt 100%.
- Dùng key ổn định cho row list quan trọng: transaction id, category id.
- Tap target icon button thường tối thiểu 44 px ở các component input/audio.
- Form transaction reuse `TransactionEntryForm` cho quick entry và editor.
- Chart nặng có `RepaintBoundary` trong `ReportPieChart`.
- Image thumbnail dùng `cacheWidth/cacheHeight` theo device pixel ratio để tránh decode quá lớn.

## Ghi chú khi thêm UI mới
- Ưu tiên component/tokens trong `lib/shared`.
- Không tạo controller/focus node trong `build`; đặt trong `State` và dispose.
- Với list dài, dùng `ListView.builder`, `SliverList`, hoặc pagination sẵn có.
- Khi đổi responsive branch, cân nhắc giữ state bằng key ổn định, `IndexedStack`, hoặc giữ controller ở parent.
- Chưa xác định từ codebase: guideline thiết kế chính thức ngoài token Flutter hiện có.
