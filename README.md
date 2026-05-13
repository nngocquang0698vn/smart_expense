# Smart Ledger (`smart_expense`)

Ứng quản lý thu chi cá nhân (Flutter), hỗ trợ **Web** và **Android**, dữ liệu **offline** (Sembast).

## Yêu cầu

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK đã dùng khi phát triển: 3.41+)
- Trên Android: Android SDK / thiết bị hoặc emulator

## Cài dependency

```bash
cd smart_expense
flutter pub get
```

## Chạy ứng dụng

**Web (Chrome):**

```bash
flutter run -d chrome
```

**Android (thiết bị hoặc emulator đã bật):**

```bash
flutter run
```

Liệt kê thiết bị: `flutter devices`

## Build

**Web (release):**

```bash
flutter build web --release
```

Kết quả: thư mục `build/web` (triển khai lên static host).

**APK debug:**

```bash
flutter build apk --debug
```

APK: `build/app/outputs/flutter-apk/app-debug.apk`

**APK / App Bundle release** cần cấu hình ký ứng dụng (signing) trong Android Studio hoặc `key.properties` — xem [tài liệu Flutter](https://docs.flutter.dev/deployment/android).

## Dữ liệu offline

- **Sembast**: giao dịch, danh mục, meta (tên người dùng, đã onboarding).
- **Web**: IndexedDB (file `smart_expense.db` trong factory web).
- **Android**: file DB dưới thư mục ứng dụng (qua `path_provider`).

## Ghi âm và ảnh chụp hoá đơn

- App có màn **Nhập nhanh** gồm: Thu/Chi, số tiền, ngày, danh mục phổ biến, ghi chú, nút mic ghi âm, đính kèm chụp/chọn ảnh, và toggle `Cần đối soát`.
- Nếu giao dịch có audio hoặc ảnh đính kèm thì app tự ép `Cần đối soát = true`.
- Ảnh và audio được lưu **offline trong Sembast** theo dạng Base64 (`imageBase64List`, `audioBase64`) gắn trực tiếp vào bản ghi giao dịch.
- Bản này **không tích hợp OCR** và **không tích hợp speech-to-text** (đúng theo requirement).
