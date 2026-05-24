# Data Model

## Nguồn lưu trữ

Sembast database mở tại `lib/features/transactions/data/app_database.dart`.

Stores chính:

- `meta`
- `categories`
- `transactions`

SharedPreferences lưu theme và user preferences.

## Transaction

Domain entity: `LedgerTransaction`.

Storage model: `TransactionModel`.

Field chính:

- `id`: String, key Sembast.
- `title`: String.
- `amountVnd`: int.
- `isIncome`: bool.
- `categoryId`: String.
- `occurredAt`: DateTime.
- `pending`: bool.
- `complete`: bool.
- `note`: String?.
- `audio`: AudioAttachmentModel?.
- `images`: List<ImageAttachmentModel>.

Code hiện tại dùng `pending` làm source of truth duy nhất cho đối soát.

## Category

Domain entity: `LedgerCategory`.

Storage model: `CategoryModel`.

Field:

- `id`
- `name`
- `iconKey`
- `colorValue`
- `isIncome`
- `enabled`

Category hệ thống:

- `LedgerRepository.kOtherExpenseId`
- `LedgerRepository.kOtherIncomeId`

## Attachment

### ImageAttachmentModel

- `id`
- `path`
- `bundleAssetPath`
- `mimeType`
- `extension`
- `fileSize`
- `width`
- `height`
- `createdAt`
- `updatedAt`

### AudioAttachmentModel

- `id`
- `path`
- `bundleAssetPath`
- `durationMs`
- `createdAt`
- `mimeType`
- `extension`
- `fileSize`

Web lưu bytes attachment trong IndexedDB riêng. Android/IO lưu file trong application documents directory.

## User preferences

`UserPreferences` lưu trong SharedPreferences:

- `quickConfirmPending`
- `reviewReminder`

`ReviewReminderSettings`:

- `enabled`
- `mode`
- `endOfDayReminderTime`
- `intervalReminderStartTime`
- `intervalReminderEndTime`
- `intervalReminderHours`

Default nằm trong `ReviewReminderDefaults`.

## Meta app

Record `meta/app`:

- `userName`
- `onboarded`

## Seed data

- Seed asset path: `SeedAssets`.
- Seed attachment metadata: `SeedAttachments`.
- Demo đối soát: `DemoReviewDataService`.
- Dữ liệu mẫu Johny: `populateJohnyData()`.

## Validation

- Draft non-pending cần amount/category hợp lệ.
- Pending draft có thể thiếu dữ liệu để xử lý sau.
- Reminder interval hợp lệ trong khoảng `1..12` tiếng.
- Start time của interval phải trước end time.
