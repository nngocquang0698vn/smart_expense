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

Schedule luôn chọn mốc kế tiếp strictly sau thời điểm hiện tại. Nếu đang đúng mốc nhắc, lần kiểm tra kế tiếp sẽ là mốc sau đó hoặc ngày hôm sau. Với mode `interval`, các mốc được tạo từ giờ bắt đầu, cộng theo khoảng lặp và chỉ nằm trong khung giờ đã chọn.

Khi timer tới hạn, app kiểm tra lại permission, settings và số lượng pending trước khi gửi. Nếu không còn pending transaction, không gửi notification.

Demo notification sau 20 giây dùng cùng notification content, kiểm tra lại pending trước khi gửi, nhưng không thay đổi production settings.

## Demo và dữ liệu mẫu

- `DemoReviewDataService.seedPendingReviewTransactions()` tạo 3 pending demo và 1 transaction `pending=false` có media để test rule eligibility.
- Profile action **Xoá tất cả dữ liệu** gọi `LedgerRepository.clearAllTransactions()`; danh mục và settings vẫn giữ nguyên.
- Bộ dữ liệu Johny nằm ở `populateJohnyData()` và là mục riêng trong Profile.

## AI Voice Transaction Demo

- Đây là tính năng thử nghiệm, bật trong Profile > Tính năng thử nghiệm.
- Flutter chỉ lưu endpoint Render và demo token trong `UserPreferences`; không lưu `OPENAI_API_KEY`.
- Quick voice entry upload audio sau khi dừng ghi âm nếu feature đang bật.
- Mọi transaction form có audio và AI đã bật đều có nút `AI đọc ghi âm` cạnh hàng `Chờ đối soát`.
- Draft từ AI luôn bị force `pending=true` ở Flutter, không trust backend.
- Nếu `transactionDate` null hoặc không parse được, app giữ ngày đang có trong form.
- Nếu API lỗi, app không xoá audio, note, amount, title hoặc category hiện tại.
- User luôn review trước khi save/confirm; app không auto-save và không auto-confirm pending transaction.
- API client timeout sau 10 giây và chỉ log debug metadata an toàn, không log demo token hoặc audio bytes.

## Edge cases

- Không có transaction: dashboard/report/pending hiển thị empty state.
- Category disabled vẫn giữ lịch sử; picker ẩn category disabled.
- Category hệ thống `Khác` không được xoá.
- Web/iOS/PWA có thể giới hạn notification/audio; app phải có fallback UI và không autoplay audio.
