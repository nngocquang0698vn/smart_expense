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

**Web (release, PWA offline-first):**

```bash
flutter build web --release --pwa-strategy=none
```

Kết quả: thư mục `build/web` (triển khai lên static host). File `web/_redirects` được copy sang `build/web` để SPA fallback trên Cloudflare Pages.

**Kiểm tra bản build local:**

```bash
# Sau khi build, serve thư mục build/web (vd. dùng npx serve)
npx --yes serve build/web -p 8080
```

Mở DevTools → Application: kiểm tra manifest, service worker, icons.

## PWA và cài lên màn hình chính

- Web có manifest, theme `#006B68`, icon trong `web/icons/`.
- Trên trình duyệt (không phải APK Android), app có thể gợi ý **Cài lên màn hình chính** (Android Chrome / iOS Safari / desktop Chromium).
- Dữ liệu giao dịch vẫn lưu cục bộ (Sembast); service worker cache shell app để mở lại khi offline sau lần tải đầu.
- Vào **Cá nhân** → **Cài app lên màn hình chính** để xem lại hướng dẫn.

**Giới hạn:** iOS không hỗ trợ cài tự động như Chrome; `beforeinstallprompt` chỉ có trên Chromium (HTTPS + tiêu chí trình duyệt).

## Deploy Cloudflare Pages (GitHub Actions)

Workflow: [`.github/workflows/deploy-cloudflare-pages.yml`](.github/workflows/deploy-cloudflare-pages.yml)

- Trigger: push nhánh `main` hoặc `workflow_dispatch`.
- Chạy: `flutter analyze`, `flutter test`, `flutter build web --release --pwa-strategy=none`, deploy `build/web`.

**GitHub Secrets** (tab Secrets):

| Secret | Mô tả |
|--------|--------|
| `CLOUDFLARE_API_TOKEN` | API token có quyền **Account → Cloudflare Pages → Edit** |
| `CLOUDFLARE_ACCOUNT_ID` | Account ID (Dashboard → Overview) |

**GitHub Variable** (tab Variables — không phải Secrets):

| Variable | Mô tả |
|----------|--------|
| `CLOUDFLARE_PROJECT_NAME` | Tên project Pages **trùng khớp** Cloudflare (vd. `smartexpense`) |

Workflow ưu tiên **Variables**; chỉ dùng Secret cùng tên nếu Variable chưa có.

**Lỗi `Project not found`:** thường do nhầm **Worker** với **Pages**.

| Loại | URL Dashboard (ví dụ) | CI dùng |
|------|------------------------|---------|
| **Worker** | `.../workers/services/view/smartexpense/...` | Không — Flutter web static không deploy bằng `pages deploy` |
| **Pages** | `.../pages/view/smartexpense` hoặc mục **Pages** trong sidebar | Đúng — `wrangler pages deploy build/web` |

**Tạo đúng Cloudflare Pages (lần đầu):**

1. [Cloudflare Dashboard](https://dash.cloudflare.com/) → **Workers & Pages**
2. **Create application** → chọn tab **Pages** (không chọn Workers)
3. **Create a project** → tên: `smartexpense` (khớp Variable GitHub)
4. Có thể chọn **Direct Upload** (CI sẽ upload `build/web` qua Wrangler; không bắt buộc connect Git)

Sau khi có **Pages** project `smartexpense`, re-run workflow GitHub.

Xóa Secret trùng tên `CLOUDFLARE_PROJECT_NAME` (nếu còn); chỉ giữ **Variable** = `smartexpense`.

**Lưu ý CI:** Workflow dùng `flutter build web --release --pwa-strategy=none` (Flutter service worker mặc định tắt; PWA manifest/icons vẫn từ `web/manifest.json`).

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
- Ảnh và audio lưu offline riêng: Web dùng IndexedDB binary, Android dùng file trong app documents; transaction chỉ giữ metadata/reference.
- Bản này **không tích hợp OCR** và **không tích hợp speech-to-text** (đúng theo requirement).
