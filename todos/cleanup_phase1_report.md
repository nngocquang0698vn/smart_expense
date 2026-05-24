# Smart Expense Cleanup - Phase 1 Scan Report

Date: 2026-05-24

Status: scan only. No app code, docs, assets, formatting, or cleanup changes were applied during Phase 1.

## Verification Baseline

- `git status --short`: clean before scan.
- `flutter analyze`: passed, `No issues found`.
- `flutter test`: passed, `246 tests passed`.
- Import graph from `lib/main.dart`: no Dart file under `lib/` appears detached from the app graph.

## Project Shape Observed

- `lib/app`: bootstrap, routing, main shell, global providers, theme, localization.
- `lib/core`: constants, formatting, seed/demo helpers, attachment readers, PWA utilities, test helpers.
- `lib/features/dashboard`: dashboard summary, pending preview, history paging.
- `lib/features/transactions`: transaction domain/data/application/presentation, quick entry, editor, pending reconciliation, attachments.
- `lib/features/reports`: analytics/reporting by period and category.
- `lib/features/categories`: category management and category visuals.
- `lib/features/settings`: profile, theme/user preferences, review reminder notification, demo/sample data.
- `lib/shared`: design system, reusable components, shared layouts/dialogs.
- `test`: unit/widget tests grouped by feature.
- `docs`: project documentation.

## Dead Code Safe Candidates

### 1. Duplicate category UI helpers in storage model

File:

- `lib/features/transactions/data/models/category_model.dart`

Candidate removals:

- `import "package:flutter/material.dart";`
- `CategoryIcons`
- `kCategoryColors`

Evidence:

- `CategoryIcons` used by the app lives in `lib/features/categories/presentation/category_visuals.dart`.
- `kCategoryColors` used by category editor/UI lives in `lib/features/transactions/domain/entities/category.dart`.
- The definitions inside `category_model.dart` only appear at their own declaration site and are not imported by app usage.
- `CategoryModel` is a storage DTO and does not need Material `IconData`.

Risk:

- Very low. This should not affect runtime behavior if only the duplicate declarations are removed.

Suggested Phase 2 action:

- Remove the duplicate declarations/import from `category_model.dart`.
- Run `flutter analyze` and `flutter test`.

### 2. Unused tracked demo assets

Files:

- `assets/demo/audio_demo.mp3`
- `assets/demo/bill_demo.jpg`

Evidence:

- Not listed in `pubspec.yaml` assets.
- No usage found in `lib`, `test`, `docs`, or README via `rg`.
- Runtime seed assets use `assets/seed/audio/voice_note.mp3` and `assets/seed/images/bill.jpg`.

Risk:

- Runtime risk is effectively zero.
- Only risk is losing old demo/reference media if someone wanted to keep it manually.

Suggested Phase 2 action:

- Delete `assets/demo/`.

### 3. Tracked untrack icon source/reference files

Files:

- `untrack/stitch_pwa_icon/smart_expense_icon_foreground_adaptive.png`
- `untrack/stitch_pwa_icon/smart_expense_master_app_icon.png`

Evidence:

- App icon config uses `assets/app_icon/app_icon.png` and `assets/app_icon/app_icon_foreground.png`.
- No usage found for `untrack/stitch_pwa_icon`.

Risk:

- Runtime risk is zero.
- Keep if these are desired source/reference assets for regenerating app icons.

Suggested Phase 2 action:

- Delete only if source icon history is not needed.

## Likely Unused But Not Safe Enough To Remove Yet

### 1. Transaction `complete`

Files involved:

- `lib/features/transactions/domain/entities/ledger_transaction.dart`
- `lib/features/transactions/data/models/transaction_model.dart`
- `lib/features/transactions/data/transaction_model_mapper.dart`
- `lib/features/transactions/application/transaction_draft_validator.dart`
- `lib/core/config/demo_seed.dart`
- tests and docs

Why suspicious:

- UI confirm button recomputes completeness from `amountVnd > 0 && categoryId.isNotEmpty` in `lib/shared/components/tx_row.dart`.
- No clear app flow reads `transaction.complete` directly for behavior.

Why not removed in safe cleanup:

- The field is still written, persisted, mapped, tested, and documented.
- It may be intended as persisted review state even if the current UI recomputes it.
- Removing it touches model, mapper, validator, repository, seed data, tests, and docs.

Recommendation:

- Keep for the submission-safe cleanup.
- Consider a separate cleanup later if you confirm that `complete` should become derived-only.

### 2. Attachment metadata fields

Likely unused fields:

- `ImageAttachmentModel.updatedAt`
- `ImageAttachmentModel.fileSize`
- `ImageAttachmentModel.createdAt`
- `ImageAttachmentModel.width`
- `ImageAttachmentModel.height`
- `AudioAttachmentModel.createdAt`
- `AudioAttachmentModel.fileSize`
- `AudioAttachmentModel.extension`

Fields with clearer current value:

- `AudioAttachmentModel.durationMs`: used by `VoiceNotePlayer`.
- `AudioAttachmentModel.mimeType`: used by playback/content type.
- `bundleAssetPath`: used for bundled seed/demo media.
- `path`: used for local/web storage reference.

Why not removed:

- These fields are persisted attachment metadata.
- Several are produced by storage services and covered by tests.
- Removing them before submission has a larger blast radius than the benefit.

Recommendation:

- Keep for now.
- If cleaning later, start with `ImageAttachmentModel.updatedAt` because it looks least connected to UI/business logic.

### 3. Some design tokens in `AppColors`

Likely unused direct tokens:

- `brandYellowDark`
- `brandYellowLight`
- `textTertiary`
- `divider`
- `historyBadge`
- `surfaceAccent`
- `onSurfaceAccent`
- `desktopScaffold`

Why not removed:

- These are design-system public tokens, not feature dead code.
- Keeping a small stable token set is acceptable before submission.

Recommendation:

- Keep unless you want a stricter token cleanup pass later.

## Dependency / Asset / Config Notes

Direct dependencies in `pubspec.yaml` all appear justified by imports or config:

- `flutter_riverpod`
- `fl_chart`
- `go_router`
- `image_picker`
- `intl`
- `path`
- `path_provider`
- `sembast`
- `sembast_web`
- `uuid`
- `shared_preferences`
- `record`
- `just_audio`
- `flutter_local_notifications`
- `flutter_launcher_icons` as dev dependency/config

No direct package removal is recommended from Phase 1.

Docs/config note:

- `docs/stitch_pwa_reference.md` exists in the working tree, but `.gitignore` ignores that path. Decide whether it is meant to be local-only or part of submitted docs.
- Several docs and comments display mojibake in shell output. Some files appear readable in later searches, so this may be terminal encoding, but docs should be opened in the editor before submission to confirm Vietnamese text is clean.

## Docs To Update If Cleanup Is Confirmed

Minimum docs to update after Phase 2:

- `docs/README.md`: update "Cleanup gan nhat" to reflect actual cleanup.
- root `business_logic.md`: update or simplify stale cleanup history.

Conditional docs:

- `docs/data_model.md`: update only if transaction/model/attachment fields are removed.
- `docs/design_system.md`: update only if design tokens/components are removed.
- `README.md`, `docs/architecture.md`, `docs/business_logic.md`, `docs/user_flow.md`, `docs/development_guide.md`: mostly match current code; only update if cleanup changes their claims.

## Suggested Phase 2 Plan

Step 1:

- Remove duplicate `CategoryIcons`, duplicate `kCategoryColors`, and Material import from `category_model.dart`.

Step 2:

- Delete `assets/demo/audio_demo.mp3` and `assets/demo/bill_demo.jpg`.
- Optionally delete `untrack/stitch_pwa_icon/*` if source/reference icons are no longer needed.

Step 3:

- Keep `complete`, attachment metadata fields, and AppColors tokens unless explicitly confirmed for deeper cleanup.

Step 4:

- Update `docs/README.md` and root `business_logic.md` with a short actual-cleanup summary.
- If optional deeper cleanup happens, update `docs/data_model.md` and/or `docs/design_system.md`.

Step 5:

- Run:

```bash
flutter analyze
flutter test
flutter build web --release --pwa-strategy=none
```

## Recommended Default Decision Before Submission

Do:

- Remove duplicate category helper code from `category_model.dart`.
- Remove unused `assets/demo/*`.
- Update cleanup notes in docs.

Do not do unless there is extra time:

- Remove transaction `complete`.
- Remove attachment metadata fields.
- Trim design-system color tokens.

