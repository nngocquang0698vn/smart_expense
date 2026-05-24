# Business Logic

## Mục tiêu nghiệp vụ

Smart Ledger giúp người dùng ghi nhận thu/chi nhanh, lưu dữ liệu offline, đối soát giao dịch chưa xử lý và xem báo cáo theo danh mục.

## Domain chính

- Transaction: `LedgerTransaction`.
- Category: `LedgerCategory`.
- Attachment: `AudioAttachmentModel`, `ImageAttachmentModel`.
- Pending reconciliation: `PendingReviewTransactionUseCase`, `PendingController`.
- Report: `ReportController`, `ReportCalculations`, `LedgerQueryService`.
- User settings: `UserPreferences`, `ReviewReminderSettings`, `ThemeSettings`.

## Rule đối soát

Rule quan trọng nhất:

```text
transaction cần đối soát <=> pending == true
```

`PendingReviewTransactionUseCase.isPendingReviewTransaction()` là source of truth cho rule này.

Không được tự suy ra pending từ:

- audio attachment
- image attachment
- note
- quick input
- seed/demo data
- metadata thiếu

Audio, ảnh và note chỉ phục vụ hiển thị và giải thích ngữ cảnh trong UI.

## Trạng thái transaction

- `pending == true`: giao dịch chờ đối soát.
- `pending == false`: giao dịch đã xác nhận, được tính vào history/report.
- `complete`: transaction có đủ thông tin để xác nhận nhanh.

`confirmPending(id)` set `pending: false`, `complete: true`.

Hiện codebase không có skip/dismiss flow riêng trong màn đối soát.

## Tính tổng và báo cáo

- Thu nhập/chi tiêu lưu bằng `amountVnd` kiểu `int`.
- `isIncome == true` là thu nhập, `false` là chi tiêu.
- Dashboard summary, history và report chỉ dùng giao dịch đã xác nhận.
- Pending transaction không được tính vào `homeSummary`, `analyticsTotals`, `categoryBreakdown`.
- Report theo category lọc theo `AnalyticsPeriod` và `incomeSide`.

## Validation giao dịch

- Non-pending transaction cần amount hợp lệ và category.
- Pending transaction có thể thiếu amount/category để người dùng hoàn thiện sau.
- Giới hạn ảnh: `TransactionImageLimits.maxPerTransaction`.
- Attachment lỗi/missing không được làm hỏng flow đối soát.

## Notification nhắc đối soát

Production reminder chỉ gửi khi:

- user bật `ReviewReminderSettings.enabled`;
- settings hợp lệ;
- notification permission được cấp;
- còn ít nhất một transaction pending theo repository query;
- đã tới thời điểm được tính bởi `ReviewReminderSchedule.nextCheckAfter()`.

Mode:

- `endOfDay`: mặc định `20:30`.
- `interval`: mặc định `06:00` đến `21:00`, mỗi `4` tiếng.

Demo notification sau 20 giây dùng cùng notification content nhưng không thay đổi production settings.

## Demo và dữ liệu mẫu

- `DemoReviewDataService.seedPendingReviewTransactions()` tạo 3 pending demo và 1 transaction `pending=false` có media để test rule eligibility.
- Profile action **Xoá tất cả dữ liệu** gọi `LedgerRepository.clearAllTransactions()`; danh mục và settings vẫn giữ nguyên.
- Bộ dữ liệu Johny nằm ở `populateJohnyData()` và là mục riêng trong Profile.

## Edge cases

- Không có transaction: dashboard/report/pending hiển thị empty state.
- Category disabled vẫn giữ lịch sử; picker ẩn category disabled.
- Category hệ thống `Khác` không được xoá.
- Web/iOS/PWA có thể giới hạn notification/audio; app phải có fallback UI và không autoplay audio.
