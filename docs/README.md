# Smart Ledger - Tài liệu dự án

## Tổng quan

`smart_expense` là app Flutter quản lý thu chi cá nhân offline-first. Tên hiển thị hiện tại là **Smart Ledger**. App hỗ trợ Web/PWA và Android, dùng Sembast cho dữ liệu local và Riverpod cho state.

## Module hiện có

- `lib/app/`: bootstrap, localization, router, main shell, provider toàn app.
- `lib/core/`: constants, formatter, seed data, attachment reader, PWA utilities, test helpers.
- `lib/features/dashboard/`: tổng quan thu/chi, pending preview, lịch sử.
- `lib/features/transactions/`: transaction domain/data/presentation, nhập nhanh, editor, pending reconciliation, attachment.
- `lib/features/reports/`: báo cáo theo kỳ và danh mục.
- `lib/features/categories/`: quản lý danh mục.
- `lib/features/settings/`: Profile, theme preferences, user preferences, review reminder, demo/sample data.
- `lib/shared/`: design system, reusable component, layout.
- `web/`: PWA manifest, HTML bootstrap, icon, install/notification bridge.
- `android/`: cấu hình Android Flutter.
- `test/`: unit/widget tests theo feature.

## Flow chính

- Onboarding nhập tên người dùng.
- Main shell có 4 tab: Trang chủ, Đối soát, Báo cáo, Cá nhân.
- FAB mở nhập nhanh: nhập tay, ghi âm, hoặc ảnh hoá đơn.
- Giao dịch pending được xử lý ở tab Đối soát.
- Báo cáo chỉ tính giao dịch đã xác nhận.
- Profile chứa cài đặt, nhắc đối soát, demo đối soát và dữ liệu mẫu Johny.

## Rule nghiệp vụ nổi bật

`pending == true` là điều kiện duy nhất để một transaction cần đối soát. Audio, ảnh và ghi chú chỉ là thông tin hiển thị, không tự quyết định eligibility.

Use case trung tâm: `PendingReviewTransactionUseCase`.

## Notification nhắc đối soát

Settings trong Profile có section **Nhắc đối soát giao dịch**:

- Bật/tắt nhắc đối soát.
- Mode **Cuối ngày**, mặc định `20:30`.
- Mode **Theo khoảng thời gian**, mặc định `06:00` đến `21:00`, mỗi `4` tiếng.
- Validation khoảng lặp từ `1` đến `12` tiếng.
- Chỉ gửi notification khi có pending transaction và permission đã được cấp.

Notification tap sẽ đưa người dùng về tab **Đối soát** nếu platform/browser hỗ trợ.

## Demo và dữ liệu mẫu

Profile có hai mục riêng:

- **Demo đối soát**: tạo giao dịch demo cần đối soát, gửi notification sau 20 giây, xoá tất cả dữ liệu giao dịch.
- **Dữ liệu mẫu**: nạp bộ dữ liệu Johny.

Demo notification không thay đổi production reminder settings.

## Chạy và kiểm tra

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build web --release --pwa-strategy=none
flutter build apk --debug
```

## Tài liệu chi tiết

- `architecture.md`: kiến trúc, state, routing, storage.
- `business_logic.md`: nghiệp vụ chính và rule đối soát.
- `data_model.md`: entity/model/storage quan trọng.
- `design_system.md`: token, component, responsive guideline.
- `user_flow.md`: luồng người dùng.
- `development_guide.md`: setup, convention, checklist.
- `voice_transaction_demo.md`: setup và luồng demo AI nhận diện ghi âm.
- `stitch_pwa_reference.md`: mapping reference từ Stitch sang Flutter component.

## Cleanup gần nhất

- Xoá flow skip/dismiss đối soát không còn được gọi từ UI.
- Xoá field `dismissedReviewAt` và `lastDismissedReminderDate` vì chưa có business flow sử dụng.
- Xoá parsing schema cũ `amountCents`, `image`, `receiptImage`, `iconCodePoint` vì project chưa release production.
- Xoá localization key cũ của demo/open pending/dismiss action.
- Xoá file/layout/barrel không còn được import và helper model không còn usage.
- Gỡ direct dependency `timezone`; package vẫn có thể xuất hiện transitive qua notification plugin.
