# Smart Ledger - Business Logic Summary

Tài liệu chi tiết hiện nằm trong `docs/business_logic.md`, `docs/data_model.md` và `docs/user_flow.md`.

## Quy tắc quan trọng nhất

`pending == true` là source of truth duy nhất để transaction cần đối soát.

Attachment và metadata không tự làm transaction pending:

- audio
- image
- note
- quick input
- seed/demo data
Eligibility hiện tại:

```text
pending == true
```

Use case: `PendingReviewTransactionUseCase`.

## Luồng chính

- Ghi giao dịch thu/chi qua quick entry hoặc editor.
- Pending transaction đi vào tab Đối soát.
- Confirm pending gọi `LedgerRepository.confirmPending(id)`.
- Report và history chỉ tính transaction `pending == false`.
- Profile chứa settings, reminder notification, demo đối soát và dữ liệu mẫu Johny.

## Reminder notification

- Settings nằm trong `ReviewReminderSettings`.
- Scheduler runtime nằm trong `ReviewReminderSchedulerController`.
- App chỉ gửi notification khi bật reminder, có permission và còn pending transaction.
- Demo notification sau 20 giây không thay đổi production reminder settings.

## Cleanup gần nhất

- Xoá skip/dismiss review flow không còn UI sử dụng.
- Xoá các field đối soát phụ khỏi transaction model/entity.
- Xoá `lastDismissedReminderDate` khỏi reminder settings.
- Xoá parsing schema cũ `amountCents`, `image`, `receiptImage`, `iconCodePoint`.
- Xoá file/layout/barrel không còn được import và helper model không còn usage.
- Gỡ direct dependency `timezone`.
