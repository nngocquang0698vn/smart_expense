# Architecture

## Mục lục
- [Kiến trúc tổng quan](#kiến-trúc-tổng-quan)
- [Layer hiện tại](#layer-hiện-tại)
- [State management](#state-management)
- [Routing/navigation](#routingnavigation)
- [Data flow](#data-flow)
- [Assets và attachment](#assets-và-attachment)
- [Web/PWA và Android](#webpwa-và-android)
- [Performance considerations](#performance-considerations)
- [Testing strategy](#testing-strategy)
- [Technical debt/rủi ro](#technical-debtrủi-ro)

## Kiến trúc tổng quan
Repo đang đi theo feature-first clean architecture, được mô tả ngắn tại `lib/features/_architecture.md`. Nguồn dữ liệu chính là local repository `SembastLedgerRepository`, được inject qua Riverpod provider override trong `bootstrap()`.

## Layer hiện tại
- `presentation`: screen/widget, ví dụ `pending_screen.dart`, `analytics_screen.dart`, `transaction_editor_body.dart`.
- `application`: Riverpod controller/view model/use case, ví dụ `pending_controller.dart`, `report_controller.dart`, `dashboard_controller.dart`.
- `domain`: entity, repository contract, pure service, ví dụ `LedgerTransaction`, `LedgerRepository`, `LedgerQueryService`.
- `data`: Sembast models/mappers/repository/storage service.
- `core/shared`: constants, seed, formatter, PWA utility, design system, reusable components.

## State management
Hiện tại codebase dùng `flutter_riverpod`:
- `AsyncNotifierProvider.autoDispose` cho dashboard, report, pending, categories.
- `NotifierProvider` cho theme, user preferences, amount input, PWA install state.
- Repository và SharedPreferences được override tại `ProviderScope` trong `lib/app/bootstrap.dart`.

Các controller nghe `repo.changes` để reload sau khi data thay đổi.

## Routing/navigation
- GoRouter chỉ định tuyến root `/` và `/home` tại `lib/app/router/app_router.dart`.
- `OnboardingGate` quyết định show onboarding hay `MainShell`.
- `MainShell` tự quản lý tab bằng state `_page` và `IndexedStack`.
- Các luồng phụ chủ yếu dùng `Navigator.push`, `showModalBottomSheet`, `showDialog`.

## Data flow
Ví dụ save transaction:
1. User nhập form trong `TransactionEditorBody`.
2. UI validate qua `TransactionDraftResolver`/`TransactionDraftValidator`.
3. Gọi `LedgerRepository.addQuick` hoặc `putTransaction`.
4. `SembastLedgerRepository` ghi Sembast, xử lý xoá attachment cũ nếu cần.
5. Repository phát event qua `changes`.
6. Controller đang listen reload state.
7. UI rebuild từ `AsyncValue`.

## Assets và attachment
- App icon: `assets/app_icon`, cấu hình bằng `flutter_launcher_icons`.
- Seed media: `assets/seed/audio/voice_note.mp3`, `assets/seed/images/bill.jpg`.
- Seed attachment dùng `bundleAssetPath`, đọc bytes khi cần qua `BundleAttachmentReader`.
- Ảnh user:
  - Android/IO: file trong app documents folder `smart_expense_images`.
  - Web: IndexedDB database `smart_expense_images`, store `image_blobs`.
- Audio user:
  - Android/IO: file trong app documents folder `smart_expense_audio`.
  - Web: IndexedDB database `smart_expense_audio`, store `audio_blobs`.
- Transaction chỉ lưu metadata/reference attachment.

## Web/PWA và Android
- Web manifest: `web/manifest.json`, standalone display, portrait-primary.
- PWA install bridge: `web/pwa_install_bridge.js`.
- Cloudflare Pages workflow: `.github/workflows/deploy-cloudflare-pages.yml`.
- Android permissions: camera và record audio trong manifest.
- Android release workflow: `.github/workflows/build-apk-release.yml`.
- Android application id hiện là `com.example.smart_expense`.

## Performance considerations
- MainShell giữ tab bằng `IndexedStack`, giảm remount tab khi đổi navigation.
- Dashboard history dùng page size 20 và lazy load theo scroll threshold.
- Pending list dùng `SliverList` với key ổn định và `findChildIndexCallback`.
- Report pie chart có `RepaintBoundary`; touched slice dùng `ValueNotifier`.
- Image thumbnail lazy load bytes theo tile, dùng `cacheWidth/cacheHeight`.
- VoiceNotePlayer lazy load audio khi người dùng bấm play, không load ngay trong row.
- Các controller/focus node chính trong form được tạo ở `State.initState` và dispose đúng.

## Testing strategy
Test hiện có bao phủ:
- App shell/theme/PWA/onboarding.
- Controller/view model dashboard, pending, report, categories.
- Repository Sembast.
- Query/calculation pure domain.
- Widget transaction form, note/audio, image preview, category row.

Lệnh chuẩn:

```bash
flutter analyze
flutter test
```

## Technical debt/rủi ro
- `applicationId` Android còn là `com.example.smart_expense`; cần đổi trước release thật.
- Android release đang ký bằng debug key trong `android/app/build.gradle.kts`; cần signing config thật.
- GoRouter hiện khá mỏng, nhiều route phụ dùng `Navigator` trực tiếp; nếu app scale lớn hơn nên chuẩn hoá navigation contract.
- Một số chuỗi hard-code trong voice/audio widgets không đi qua localization đầy đủ; cần rà soát nếu yêu cầu i18n.
- `flutter build web --pwa-strategy=none` không tạo Flutter service worker mặc định; cần xác minh yêu cầu offline shell PWA.
- Chưa thấy migration/versioning rõ ràng cho Sembast schema ngoài backward-compatible parsing trong model.
