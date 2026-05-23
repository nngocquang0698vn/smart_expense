# Business Logic

## Mục lục
- [Mục tiêu nghiệp vụ](#mục-tiêu-nghiệp-vụ)
- [Domain chính](#domain-chính)
- [Rule nghiệp vụ](#rule-nghiệp-vụ)
- [Trạng thái](#trạng-thái)
- [Edge cases](#edge-cases)

## Mục tiêu nghiệp vụ
Smart Ledger giúp người dùng ghi nhận thu/chi cá nhân nhanh, sau đó đối soát các giao dịch chưa đủ thông tin. Ứng dụng ưu tiên sử dụng offline trên Web/PWA và Android, không thấy tích hợp backend hoặc đồng bộ cloud trong codebase hiện tại.

## Domain chính
- **Transaction**: entity `LedgerTransaction` tại `lib/features/transactions/domain/entities/ledger_transaction.dart`.
- **Category**: entity `LedgerCategory` tại `lib/features/transactions/domain/entities/category.dart`.
- **Report**: tổng hợp thu/chi và breakdown category trong `lib/features/reports`.
- **Pending reconciliation**: luồng đối soát giao dịch `pending == true` trong `lib/features/transactions/application/pending`.
- **Attachment**: ghi chú text, ảnh, audio trong `lib/features/transactions/domain/entities/attachments`.
- **Filter/date range**: `DateFilterSelection`, `AnalyticsPeriod` tại `lib/features/transactions/domain/entities/date_filter.dart`.

## Rule nghiệp vụ
- Thu nhập/chi tiêu lưu bằng `amountVnd` kiểu `int`, không dùng số thực.
- `isIncome == true` là thu nhập, `false` là chi tiêu.
- UI tiền dùng `MoneyText`: thu nhập có dấu `+`, chi tiêu có dấu trừ và màu theo finance theme.
- Giao dịch đã xác nhận là giao dịch `pending == false`; các truy vấn report/history chỉ tính giao dịch không pending qua `LedgerQueryService._confirmedInRange`.
- Giao dịch chờ đối soát là giao dịch `pending == true`.
- `confirmPending(id)` chuyển giao dịch sang `pending: false`, `complete: true`.
- `complete` thể hiện giao dịch có đủ amount và category để xác nhận nhanh; logic nằm trong `TransactionDraftValidator`.
- Giao dịch có ghi chú khi `note` khác `null`.
- Giao dịch có audio khi `audio != null`.
- Giao dịch có ảnh khi `images.isNotEmpty`.
- Multiple image attachment giới hạn tối đa `5` ảnh/transaction tại `TransactionImageLimits.maxPerTransaction`.
- Report theo category dùng `categoryBreakdown`, chỉ lấy giao dịch confirmed, lọc theo kỳ và theo `incomeSide`.
- Category bị disable vẫn giữ lịch sử; UI row fallback biểu tượng/tên "Khác" khi category disabled.

## Trạng thái
- Loading/error/empty được xử lý ở nhiều màn hình bằng `AsyncValue.when`, `AppEmptyState`, `AppLoadingState`.
- Pending filter hỗ trợ: tất cả, có ảnh, có ghi âm, có ảnh/ghi âm, không có tệp.
- Luồng "Skip" riêng: **Chưa xác định từ codebase**. Code hiện tại có `Trước`/`Sau`; không thấy handler skip độc lập trong pending UI.
- Onboarding state lưu trong meta Sembast: `onboarded`.
- User preference `quickConfirmPending` lưu trong SharedPreferences.

## Edge cases
- Không có transaction: dashboard/report/pending hiển thị empty state.
- Category thiếu hoặc disabled: report bỏ slice nếu không tìm thấy category; transaction row dùng fallback visual.
- Amount lớn: input clamp theo `kMaxAmountVnd` trong `core/utils/amount_input.dart`.
- Transaction không attachment: filter `withoutAttachments` có thể chọn các giao dịch không ảnh/audio.
- Audio/image missing: attachment preview/player hiển thị lỗi nếu storage không đọc được.
- Transaction model có hỗ trợ dữ liệu legacy ảnh đơn qua key `image` hoặc `receiptImage`.
- Chưa xác định từ codebase: rule đồng bộ dữ liệu giữa nhiều thiết bị, vì không thấy backend/sync.
