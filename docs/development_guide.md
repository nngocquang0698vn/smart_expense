# Development Guide

## Setup

```bash
flutter pub get
flutter devices
```

Chạy Web:

```bash
flutter run -d chrome
```

Chạy Android:

```bash
flutter run
```

## Checklist trước commit

```bash
dart format .
flutter analyze
flutter test
```

Build check khi cần:

```bash
flutter build web --release --pwa-strategy=none
flutter build apk --debug
```

## Convention

- Import dùng double quotes.
- Feature-first theo `domain`, `application`, `data`, `presentation`.
- Pure business rule đặt trong domain/application service.
- Widget không chứa filter/business logic phức tạp trong `build`.
- Text UI mới thêm vào `AppLocalizations`.
- Attachment logic đi qua service/action hiện có.
- Controller, focus node, scroll controller, subscription và timer phải dispose.

## Làm việc với transaction

- `LedgerTransaction` là entity domain.
- `TransactionModel` là model lưu Sembast.
- Mapper nằm ở `transaction_model_mapper.dart`.
- Khi thêm/xoá field transaction, cập nhật đồng bộ constructor, mapper, `toMap/fromMap`, `copyWith`, tests và docs.
- Không thêm property "để dành" nếu chưa có flow đọc/ghi rõ ràng.

## Làm việc với pending review

- Source of truth: `PendingReviewTransactionUseCase`.
- Chỉ `pending == true` mới cần đối soát.
- Audio/image/note không được dùng làm điều kiện eligibility.
- Xác nhận pending đi qua `confirmPending(id)`.

## Làm việc với reminder notification

- Settings model: `ReviewReminderSettings`.
- Defaults: `ReviewReminderDefaults`.
- Schedule pure logic: `ReviewReminderSchedule`.
- Runtime service: `ReviewReminderSchedulerController`.
- Platform implementation nằm trong `features/settings/application/notifications`.
- Demo notification không được sửa production settings.

## Seed/demo data

- Johny sample data: `populateJohnyData()`.
- Demo đối soát: `DemoReviewDataService`.
- Seed media: `SeedAttachments`, `SeedAssets`.
- Action xoá tất cả dữ liệu chỉ xoá transaction, không xoá category/settings.

## Dependency hygiene

- Không thêm dependency lớn nếu chưa cần.
- Nếu gỡ package, dùng:

```bash
flutter pub remove <package>
```

- `pubspec.lock` có thể vẫn chứa package transitive; chỉ xem là dependency trực tiếp nếu còn trong `pubspec.yaml`.

## Responsive check thủ công

- Mobile dưới `1000px`.
- Desktop từ `1000px`.
- Pending master-detail.
- Report master-detail.
- Profile sections.
- Notification tap trên Web/PWA và Android nếu platform cho phép.
