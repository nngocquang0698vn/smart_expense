# Data Model

## Mục lục
- [Nguồn lưu trữ](#nguồn-lưu-trữ)
- [Transaction](#transaction)
- [Category](#category)
- [Attachment](#attachment)
- [Date/filter/report](#datefilterreport)
- [Seed data](#seed-data)
- [Validation](#validation)

## Nguồn lưu trữ
Sembast database mở tại `lib/features/transactions/data/app_database.dart`.

Stores chính trong `SembastLedgerRepository`:
- `meta`
- `categories`
- `transactions`

Web dùng `databaseFactoryWeb.openDatabase("smart_expense.db")`. Non-web dùng file `smart_expense.db` trong application documents directory.

## Transaction
Entity: `LedgerTransaction`.

Schema model: `TransactionModel` tại `lib/features/transactions/data/models/transaction_model.dart`.

Field quan trọng:
- `id`: required, String, key Sembast.
- `title`: required.
- `amountVnd`: required int.
- `isIncome`: required bool.
- `categoryId`: required String.
- `occurredAt`: required DateTime ISO string khi lưu.
- `pending`: required bool.
- `complete`: required bool.
- `note`: optional String.
- `audio`: optional `AudioAttachmentModel`.
- `images`: list `ImageAttachmentModel`, default empty.

Backward compatibility:
- `amountCents` legacy được convert sang `amountVnd`.
- Legacy single image từ `image` hoặc `receiptImage` được map sang list `images`.

## Category
Entity: `LedgerCategory`.

Schema model: `CategoryModel` tại `lib/features/transactions/data/models/category_model.dart`.

Field:
- `id`: required.
- `name`: required.
- `iconKey`: required, map qua `CategoryIcons.byName`.
- `colorValue`: required ARGB int.
- `isIncome`: required bool.
- `enabled`: bool, default true.

Category hệ thống:
- `LedgerRepository.kOtherExpenseId`
- `LedgerRepository.kOtherIncomeId`

Không được xoá category hệ thống theo `CategoryEditorPolicy`.

## Attachment
### ImageAttachmentModel
Path: `lib/features/transactions/domain/entities/attachments/image_attachment_model.dart`.

Field:
- `id`: required.
- `path`: optional, dùng trên IO/Android.
- `bundleAssetPath`: optional, dùng seed asset.
- `mimeType`, `extension`, `fileSize`, `width`, `height`, `createdAt`, `updatedAt`.

### AudioAttachmentModel
Path: `lib/features/transactions/domain/entities/attachments/audio_attachment_model.dart`.

Field:
- `id`: required.
- `path`: optional.
- `bundleAssetPath`: optional.
- `durationMs`, `createdAt`, `mimeType`, `extension`, `fileSize`.

Storage:
- Web lưu bytes trong IndexedDB riêng cho image/audio.
- Android/IO lưu file dưới app documents.

## Date/filter/report
- `DateFilterPreset`: last30Days, thisWeek, thisMonth, thisYear, allTime, pickMonth, pickYear, custom.
- `DateFilterSelection.resolveRange()` tạo range dùng cho query.
- `AnalyticsPeriod`: week, month, quarter, year, custom.
- `FinanceTotals`: income, expense, balance.
- `ReportCategorySlice`: category, amount, id.

## Seed data
- Seed assets: `lib/core/seed/seed_assets.dart`.
- Seed attachment meta: `lib/core/seed/seed_attachments.dart`.
- Demo data Johny: `lib/core/config/demo_seed.dart`.
- Seed dùng ngày reference `2026-05-10` và shift theo ngày hiện tại khi populate.

## Validation
- Transaction draft:
  - Pending transaction có thể lưu dù thiếu amount/category.
  - Non-pending cần amount > 0 và category.
  - Editor full yêu cầu title khi save existing/new trong `TransactionEditorBody`.
- Category draft:
  - Name trim không được rỗng.
  - Không xoá category hệ thống.
  - Không xoá category đang được transaction dùng.
- Image:
  - Tối đa 5 ảnh/transaction.
  - Picker resize maxWidth 1600 và jpegQuality 82.

Chưa xác định từ codebase: constraint DB cấp thấp cho unique category name; hiện validation name chủ yếu kiểm tra rỗng.
