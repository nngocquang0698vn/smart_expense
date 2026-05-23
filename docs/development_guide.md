# Development Guide

## Mục lục
- [Setup môi trường](#setup-môi-trường)
- [Chạy app](#chạy-app)
- [Thêm screen/component/route](#thêm-screencomponentroute)
- [Thêm category/seed/asset](#thêm-categoryseedasset)
- [Coding conventions](#coding-conventions)
- [Checklist trước commit](#checklist-trước-commit)

## Setup môi trường
1. Cài Flutter SDK phù hợp `sdk: ^3.11.5`.
2. Cài Android SDK/emulator nếu build Android.
3. Chạy:

```bash
flutter pub get
flutter devices
```

## Chạy app
Web:

```bash
flutter run -d chrome
```

Android:

```bash
flutter run
```

Analyze/test:

```bash
flutter analyze
flutter test
```

## Thêm screen/component/route
### Thêm screen mới
- Tạo trong feature tương ứng dưới `lib/features/<feature>/presentation`.
- Nếu có state/data, thêm controller/view model trong `application`.
- Business rule/pure logic đặt ở `domain` hoặc `application`, không đặt trực tiếp trong widget build.

### Thêm component mới
- Component reusable toàn app đặt trong `lib/shared/components`.
- Component chỉ dùng trong feature đặt dưới `presentation/widgets`.
- Dùng tokens từ `lib/shared/design_system`.
- Dùng localization từ `context.l10n`, tránh hard-code text mới.

### Thêm route mới
- Route root hiện nằm tại `lib/app/router/app_router.dart`.
- Tab chính hiện nằm trong `MainShell` bằng `_navItems` và `_pages`.
- Các flow modal hiện dùng bottom sheet/dialog. Nếu thêm deep link hoặc route độc lập, nên mở rộng GoRouter thay vì chỉ dùng `Navigator.push`.

## Thêm category/seed/asset
### Category
- Icon key khai báo trong `CategoryIcons.byName`.
- Color preset trong `kCategoryColors`.
- Default/system category được seed/ensure trong `SembastLedgerRepository`.

### Seed data
- Demo data nằm trong `lib/core/config/demo_seed.dart`.
- Seed media path nằm trong `lib/core/seed/seed_assets.dart`.
- Nếu thêm asset seed mới, cập nhật `pubspec.yaml` assets.

### Asset audio/image
- Seed assets hiện ở `assets/seed/audio/` và `assets/seed/images/`.
- App icon ở `assets/app_icon/`.
- Web icons generated ở `web/icons/`.
- Cập nhật app icon qua cấu hình `flutter_launcher_icons` trong `pubspec.yaml`.

## Coding conventions
- Import dùng double quotes theo codebase hiện tại.
- Feature-first: `domain -> application -> data -> presentation`.
- Riverpod controller nên listen `repo.changes` nếu cần phản ứng với data update.
- Controller, `TextEditingController`, `FocusNode`, `ScrollController`, `PageController`, subscription, timer phải dispose đúng.
- Future dùng trong `FutureBuilder` nên cache trong state nếu dữ liệu không cần tạo lại mỗi build.
- List item nên có stable key theo id.
- Transaction form nên reuse `TransactionEntryForm`.
- Attachment logic nên đi qua service/action hiện có, không đọc/ghi file trực tiếp trong widget mới.

## Checklist trước commit
- Format:

```bash
dart format .
```

- Analyze:

```bash
flutter analyze
```

- Test:

```bash
flutter test
```

- Responsive check:
  - Mobile width dưới `1000`.
  - Desktop width từ `1000`.
  - Pending master-detail và report master-detail.
  - Web resize không làm mất text/note/audio đang nhập.

- Web build check:

```bash
flutter build web --release --pwa-strategy=none
```

- Android check:

```bash
flutter build apk --debug
```

Chưa xác định từ codebase: quy định branch/PR/release versioning của team ngoài workflow GitHub hiện có.
