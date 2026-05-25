# Smart Ledger (`smart_expense`)

Ứng dụng quản lý thu chi cá nhân bằng Flutter, hỗ trợ **Web/PWA** và **Android**. Dữ liệu giao dịch, danh mục và thiết lập được lưu cục bộ, không phụ thuộc backend.

## Tính năng chính

- Ghi thu/chi nhanh bằng nhập tay, ghi âm hoặc ảnh hoá đơn.
- Đối soát giao dịch đang chờ xử lý.
- Báo cáo thu/chi theo kỳ và theo danh mục.
- Quản lý danh mục thu/chi.
- Cài đặt giao diện, xác nhận nhanh, nhắc đối soát giao dịch.
- Profile có khu vực **Demo đối soát** và **Dữ liệu mẫu** để trình diễn nhanh.

## Rule đối soát quan trọng

`pending == true` là nguồn sự thật duy nhất để giao dịch xuất hiện trong luồng đối soát.

Audio, ảnh và ghi chú chỉ là metadata hỗ trợ người dùng hiểu vì sao cần kiểm tra lại. Chúng không tự làm giao dịch trở thành pending.

Khi xác nhận pending, repository set:

- `pending: false`
- `complete: true`

## Yêu cầu môi trường

- Flutter SDK tương thích `environment.sdk` trong `pubspec.yaml`.
- Android SDK/emulator nếu chạy hoặc build Android.
- Chrome/Edge nếu chạy Web/PWA.

## Cài dependency

```bash
flutter pub get
```

## Chạy ứng dụng

Web:

```bash
flutter run -d chrome
```

Android:

```bash
flutter run
```

Liệt kê thiết bị:

```bash
flutter devices
```

## Verify

```bash
dart format .
flutter analyze
flutter test
```

## Build

Web release:

```bash
flutter build web --release --pwa-strategy=none
```

Android debug APK:

```bash
flutter build apk --debug
```

Android release APK cần cấu hình signing riêng trước khi phân phối thật.

## PWA và notification

- Web manifest, icon và install bridge nằm trong `web/`.
- `web/pwa_install_bridge.js` hỗ trợ cài PWA và notification click bridge cho luồng đối soát.
- Trên Web, notification chỉ hoạt động khi browser cho phép và app được chạy trong context phù hợp.
- Trên Android, app dùng `flutter_local_notifications` và quyền notification trong manifest.

## Dữ liệu offline

- Sembast store chính: `meta`, `categories`, `transactions`.
- Web dùng IndexedDB.
- Android/IO dùng file trong application documents directory.
- Attachment ảnh/audio lưu riêng theo nền tảng; transaction chỉ giữ metadata/reference.

## AI Voice Transaction Demo

- Bật trong Profile > Tính năng thử nghiệm.
- User nhập endpoint Render và demo token. Flutter không chứa `OPENAI_API_KEY`.
- OpenAI API key nằm trên Render backend.
- Nút `Đánh thức API demo` gọi `/health` trước khi thuyết trình vì Render free có thể sleep; khi OK app báo service đang hoạt động.
- Quick voice entry tự gọi API sau khi dừng ghi âm và autofill form, nhưng không auto-save.
- Khi transaction/form có audio và AI đã bật, nút `AI đọc ghi âm` nằm bên phải hàng `Chờ đối soát`.
- Draft từ AI luôn `pending=true`; user phải review trước khi lưu/xác nhận.
- Nếu API lỗi, app vẫn giữ audio/note/dữ liệu đang nhập để user lưu và đối soát sau.
- API demo có timeout 10 giây và log debug trong console với prefix `[AI Voice Demo]`; không log token hoặc raw audio bytes.

## Tài liệu

Tài liệu chi tiết nằm trong thư mục `docs/`:

- `docs/architecture.md`
- `docs/business_logic.md`
- `docs/data_model.md`
- `docs/design_system.md`
- `docs/user_flow.md`
- `docs/development_guide.md`
- `docs/voice_transaction_demo.md`
