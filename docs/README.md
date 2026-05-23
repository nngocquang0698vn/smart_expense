# Smart Ledger - Tài liệu dự án

## Mục lục
- [Tổng quan](#tổng-quan)
- [Nền tảng hỗ trợ](#nền-tảng-hỗ-trợ)
- [Tính năng chính](#tính-năng-chính)
- [Cấu trúc thư mục](#cấu-trúc-thư-mục)
- [Chạy và build local](#chạy-và-build-local)
- [Deploy Web/PWA](#deploy-webpwa)
- [Ghi chú onboarding dev mới](#ghi-chú-onboarding-dev-mới)

## Tổng quan
`smart_expense` là app Flutter quản lý thu chi cá nhân offline-first. Codebase hiện tại dùng tên hiển thị **Smart Ledger**, dữ liệu lưu cục bộ qua Sembast và các attachment ảnh/audio được lưu riêng theo nền tảng.

App tập trung vào:
- Ghi giao dịch thu/chi nhanh.
- Gắn ghi chú, ảnh hoá đơn và ghi âm.
- Đưa giao dịch chưa đủ thông tin vào luồng đối soát.
- Xem lịch sử và báo cáo theo hạng mục.
- Chạy trên Flutter Web/PWA và Android.

## Nền tảng hỗ trợ
- **Flutter Web/PWA**: có `web/manifest.json`, icon trong `web/icons/`, bridge cài PWA tại `web/pwa_install_bridge.js`, fallback SPA tại `web/_redirects`.
- **Android**: cấu hình trong `android/app`, quyền camera và micro nằm trong `android/app/src/main/AndroidManifest.xml`.

Chưa xác định từ codebase: iOS chưa được cấu hình launcher icon trong `pubspec.yaml` (`ios: false`) và không thấy cấu hình build/release iOS.

## Tính năng chính
- Onboarding nhập tên người dùng: `lib/features/onboarding/presentation/onboarding_screen.dart`.
- Main shell 4 tab: Trang chủ, Đối soát, Báo cáo, Cá nhân trong `lib/app/main_shell.dart`.
- Dashboard tổng quan thu/chi, pending preview, lịch sử phân trang: `lib/features/dashboard`.
- Thêm nhanh giao dịch dạng bottom sheet: `lib/features/transactions/presentation/quick_entry_sheet.dart`.
- Sửa giao dịch: `lib/features/transactions/presentation/transaction_editor_body.dart`.
- Đối soát giao dịch chờ xử lý: `lib/features/transactions/presentation/pending`.
- Báo cáo theo kỳ và hạng mục, có pie chart: `lib/features/reports`.
- Quản lý hạng mục: `lib/features/categories`.
- Cài đặt cá nhân, theme, demo seed, PWA install entry: `lib/features/settings/presentation/profile_screen.dart`.

## Cấu trúc thư mục
- `lib/app/`: bootstrap, `MaterialApp.router`, GoRouter, main shell, providers toàn app, localization.
- `lib/core/`: constants, seed data, storage helper, formatter, PWA utilities.
- `lib/features/`: feature-first theo `domain`, `application`, `data`, `presentation`.
- `lib/shared/`: design system, component reusable, layout reusable.
- `assets/seed/`: audio/image seed dùng trong dữ liệu demo.
- `web/`: manifest, icon, HTML bootstrap, PWA install bridge.
- `android/`: project Android Flutter.
- `test/`: unit/widget tests theo app, core, features, shared.

## Chạy và build local
Yêu cầu: Flutter SDK tương thích `environment.sdk: ^3.11.5`.

```bash
flutter pub get
flutter run -d chrome
flutter run
```

Build Web:

```bash
flutter build web --release --pwa-strategy=none
```

Build Android:

```bash
flutter build apk --debug
flutter build apk --release
```

Các lệnh thường dùng:

```bash
flutter analyze
flutter test
flutter build web --release --pwa-strategy=none
```

## Deploy Web/PWA
Repo có workflow Cloudflare Pages tại `.github/workflows/deploy-cloudflare-pages.yml`.

Workflow hiện tại:
- chạy `flutter pub get`
- chạy `flutter analyze`
- chạy `flutter test`
- build `flutter build web --release --pwa-strategy=none`
- deploy `build/web` bằng Wrangler Pages

Cấu hình cần có:
- Secret `CLOUDFLARE_API_TOKEN`
- Secret `CLOUDFLARE_ACCOUNT_ID`
- Variable hoặc Secret `CLOUDFLARE_PROJECT_NAME`

Lưu ý: `--pwa-strategy=none` tắt Flutter service worker mặc định. Manifest/icons vẫn có, nhưng offline cache app shell cần xác minh thêm bằng Chrome DevTools nếu muốn cam kết PWA offline đầy đủ.

## Ghi chú onboarding dev mới
- State management chính là Riverpod 3 (`flutter_riverpod`).
- Data source chính là Sembast, không thấy backend/cloud sync trong codebase.
- Repository contract nằm tại `lib/features/transactions/domain/repositories/ledger_repository.dart`.
- Dữ liệu demo tạo bằng `populateJohnyData` trong `lib/core/config/demo_seed.dart`.
- UI text tập trung ở `lib/app/localization/app_localizations.dart`, hiện chỉ thấy tiếng Việt.
- Trước khi commit nên chạy `flutter analyze` và `flutter test`.
