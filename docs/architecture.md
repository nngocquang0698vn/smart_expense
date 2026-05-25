# Architecture

## Tổng quan

Codebase đi theo feature-first clean architecture nhẹ:

```text
presentation -> application -> domain
                         data -> domain
```

UI không đọc/ghi Sembast trực tiếp. Dữ liệu đi qua `LedgerRepository`, được inject bằng Riverpod trong `bootstrap()`.

## Layer

- `presentation`: screen/widget, ví dụ `pending_screen.dart`, `profile_screen.dart`, `analytics_screen.dart`.
- `application`: controller, view model, use case, service orchestration.
- `domain`: entity, repository contract, pure business service.
- `data`: Sembast repository, model, mapper, attachment storage.
- `shared`: design system và component reusable.
- `core`: helper dùng chung, seed, PWA utilities.

## State management

App dùng Riverpod:

- `AsyncNotifierProvider.autoDispose` cho dashboard, pending, report, categories.
- `NotifierProvider` cho theme, user preferences, PWA install state, voice recorder.
- Repository provider được override trong `ProviderScope`.

Các controller lắng nghe `repo.changes` để reload sau khi data thay đổi.

## Navigation

- GoRouter hiện có root route mỏng tại `app_router.dart`.
- `MainShell` quản lý 4 tab bằng state nội bộ và `IndexedStack`.
- Notification tap stream được lắng nghe trong `MainShell`; khi tap review notification, app chuyển sang tab Đối soát và hiện snackbar nhỏ.
- Modal flow dùng `Navigator`, bottom sheet và dialog theo nhu cầu từng feature.

## Data flow mẫu

Save transaction:

1. User nhập form.
2. UI resolve draft và validate.
3. Repository `addQuick()` hoặc `putTransaction()`.
4. `SembastLedgerRepository` ghi model, xử lý attachment cũ nếu cần.
5. Repository phát `changes`.
6. Controller reload state.
7. UI rebuild từ `AsyncValue`.

Confirm pending:

1. UI gọi `runConfirmPendingFlow()`.
2. Nếu tắt quick confirm, hiện confirm bottom sheet.
3. Repository `confirmPending(id)`.
4. Transaction chuyển `pending=false`, `complete=true`.

## Notification architecture

- Settings model: `ReviewReminderSettings`.
- Schedule logic: `ReviewReminderSchedule`.
- Runtime orchestration: `ReviewReminderSchedulerController`.
- Platform bridge: `ReviewNotificationPlatform` với implementation Web/IO/Stub.
- Copy notification: `ReviewReminderCopy`.

Scheduler dùng timer trong runtime app; demo notification sau 20 giây không ghi đè production settings.
Controller reschedule khi settings hoặc repository phát `changes`, và kiểm tra lại permission/pending count ngay trước lúc gọi platform notification để tránh nhắc khi danh sách đối soát đã trống.

## Attachment architecture

- Transaction chỉ lưu metadata/reference.
- Web dùng IndexedDB binary store cho audio/image.
- Android/IO dùng file trong app documents directory.
- Audio player lazy-load khi user bấm play.
- Image thumbnail đọc bytes theo tile.

## AI Voice Demo Architecture

- Config nằm trong `UserPreferences`: bật/tắt, endpoint Render, demo token.
- Profile section `Tính năng thử nghiệm` quản lý config và gọi `/health` để wake Render.
- `VoiceTransactionDemoApiClient` gọi multipart `POST /voice-transaction-demo`.
- API client gọi `/health` và `/voice-transaction-demo` với timeout 10 giây, log debug bằng prefix `[AI Voice Demo]`.
- Audio upload đọc bytes qua `AudioStorageService`, nên dùng được cả IO path, Web IndexedDB và bundled seed asset.
- `VoiceTransactionDemoMapper` map response vào form patch, resolve category theo local default IDs/key/name.
- UI quick entry, transaction editor và pending editor đặt nút `AI đọc ghi âm` cạnh hàng `Chờ đối soát` khi form có audio.
- UI chỉ apply patch sau success; fail không xoá dữ liệu user.
- OpenAI API key không đi vào Flutter, chỉ nằm ở Render backend.

## Web/PWA và Android

- Web: `manifest.json`, `pwa_install_bridge.js`, `_redirects`.
- Android: manifest có camera, record audio và notification permission.
- `flutter_local_notifications` dùng cho Android/local notification support.

## Performance

- `MainShell` giữ tab bằng `IndexedStack`.
- Dashboard history phân trang.
- Pending list dùng stable key và sliver/list layout.
- Report chart có `RepaintBoundary`.
- Attachment preview/player lazy-load.

## Testing

Test hiện có bao phủ:

- domain/use case pending rule;
- repository Sembast;
- settings/review reminder schedule;
- dashboard/report/category controller;
- transaction form, note/audio/image widget;
- PWA install utilities;
- architecture feature-first convention.

Lệnh chuẩn:

```bash
flutter analyze
flutter test
```

## Technical debt/rủi ro

- Android `applicationId` còn là `com.example.smart_expense`.
- Android release signing cần cấu hình trước production.
- GoRouter còn mỏng; nếu cần deep link phức tạp nên chuẩn hoá route contract.
- App chưa có backend/cloud sync.
- Sembast schema chưa có migration versioning riêng; project chưa release nên cleanup model vẫn ưu tiên đơn giản.
