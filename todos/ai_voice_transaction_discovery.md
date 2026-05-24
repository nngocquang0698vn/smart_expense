# AI Voice Transaction Discovery Report

Date: 2026-05-24

Scope: discovery only. No app code, existing docs, backend files, dependencies, or UI flow were changed.

## 1. Project Overview

- Framework/version:
  - Flutter 3.41.9 stable, Dart 3.11.5 from `flutter --version`.
  - Dart SDK constraint: `^3.11.5` in `pubspec.yaml`.
- App targets:
  - Web/PWA: `web/index.html`, `web/manifest.json`, `web/pwa_install_bridge.js`.
  - Android: `android/app/...`; app label `Smart Ledger`; permissions include camera, record audio, post notifications.
- State management:
  - Riverpod via `flutter_riverpod: ^3.0.3`.
  - Global providers in `lib/app/providers.dart`.
  - Bootstrap overrides `SharedPreferences` and `LedgerRepository` in `lib/app/bootstrap.dart`.
- Routing/navigation:
  - `go_router: ^17.0.0`.
  - `appRouterProvider` in `lib/app/router/app_router.dart`.
  - Main runtime navigation is tab-based inside `MainShell` with an `IndexedStack` in `lib/app/main_shell.dart`.
  - Current tabs: Dashboard, Pending, Analytics, Profile.
- HTTP client/package:
  - Not found.
  - No direct `http`, `dio`, `HttpClient`, `MultipartRequest`, `Uri.parse`, or API client package usage found in `lib`, `test`, `pubspec.yaml`, `docs`, `android`, or `web`.
- Local storage/database:
  - Ledger database: Sembast (`sembast`, `sembast_web`) via `lib/features/transactions/data/app_database.dart`.
  - Web ledger DB: `smart_expense.db` through `databaseFactoryWeb`.
  - IO/Android ledger DB: file `smart_expense.db` in application documents directory.
  - Shared preferences: `shared_preferences` for theme and user preferences.
  - Audio/image attachment binary storage is platform-specific and separate from transaction metadata.
- Config/env/flavor mechanism:
  - Not found for runtime API config.
  - No `String.fromEnvironment`, `bool.fromEnvironment`, `--dart-define`, flavor config, API base URL, or `.env` mechanism found in app code.

## 2. Current Audio Recording Flow

- Recording component/service:
  - `lib/features/transactions/data/attachments/voice_recorder_service.dart`
  - `lib/features/transactions/application/voice_note/voice_recorder_controller.dart`
  - `lib/features/transactions/presentation/widgets/transaction_note_input.dart`
  - Older/separate reusable UI also exists at `lib/features/transactions/presentation/voice_note/widgets/voice_recorder_input.dart`.
- Recording package:
  - `record: ^6.2.0`.
  - `VoiceRecorderService` wraps `AudioRecorder`.
- Audio output:
  - `VoiceRecorderService.stop()` receives a temporary recording path from `record`, reads bytes through `VoiceNoteFileService.readRecordingBytes(path)`, then persists bytes using `AudioStorageService.saveRecording(...)`.
  - App stores an `AudioAttachmentModel`, not raw base64.
  - IO/Android stores a real file path in `AudioAttachmentModel.path`.
  - Web stores bytes in IndexedDB store `audio_blobs` and references them by `AudioAttachmentModel.id`; `path` is normally null on Web.
- Audio mime type/format:
  - Encoder selection tries `AudioEncoder.aacLc`, `AudioEncoder.opus`, then `AudioEncoder.wav`; fallback is `aacLc`.
  - Extensions map to `.m4a`, `.opus`, `.wav`.
  - `AudioStorageHelper.contentTypeForBytes(bytes)` detects `audio/wav`, `audio/webm`, `audio/mpeg`, `audio/ogg`, otherwise defaults to `audio/mp4`.
  - Seed audio uses mp3: `assets/seed/audio/voice_note.mp3`, mime `audio/mpeg`.
- Start/stop flow:
  - Quick entry voice mode starts from `QuickEntryMode.voice` in `lib/features/transactions/presentation/quick_entry_sheet.dart`.
  - Quick entry sets `_pending = widget.mode != QuickEntryMode.tap`, so voice and receipt modes default to pending.
  - `TransactionEntryForm` passes `autoStartVoiceRecording` into `TransactionNoteInput`.
  - `TransactionNoteInput` uses `VoiceRecorderController.start()`, `pause()`, `resume()`, `finish()`, `remove()`.
  - After finish, `TransactionNoteInput` calls `widget.onAudioChanged(note.audio)`.
- After recording:
  - Audio is attached to the transaction draft as `_audio`.
  - Save calls `LedgerRepository.addQuick(...)` or `putTransaction(...)` with `audio: _audio`.
  - Transaction stores audio metadata in `TransactionModel.audio`.
- Play/pause/delete:
  - Playback uses `just_audio: ^0.10.5`.
  - `VoiceNotePlayer` is in `lib/features/transactions/presentation/voice_note/widgets/voice_note_player.dart`.
  - Playback service is `lib/features/transactions/data/attachments/voice_player_service.dart`.
  - Delete/remove is supported from `TransactionNoteInput` and `VoiceRecorderInput`; repository deletes old audio when replacing or deleting transactions.
- Related files:
  - `lib/features/transactions/domain/entities/attachments/audio_attachment_model.dart`
  - `lib/features/transactions/domain/entities/attachments/voice_note_model.dart`
  - `lib/features/transactions/domain/entities/attachments/voice_recording_status.dart`
  - `lib/features/transactions/domain/repositories/voice_recorder_repository.dart`
  - `lib/features/transactions/data/attachments/audio_storage_service.dart`
  - `lib/features/transactions/data/attachments/audio_storage_service_io.dart`
  - `lib/features/transactions/data/attachments/audio_storage_service_web.dart`
  - `lib/features/transactions/data/attachments/voice_note_file_service.dart`
  - `lib/features/transactions/data/attachments/voice_note_file_service_io.dart`
  - `lib/features/transactions/data/attachments/voice_note_file_service_web.dart`
  - `lib/features/transactions/data/attachments/voice_playback_source_service.dart`
  - `lib/features/transactions/data/attachments/voice_playback_source_service_io.dart`
  - `lib/features/transactions/data/attachments/voice_playback_source_service_web.dart`

## 3. Current Note/Input Flow

- Note field/component:
  - `LedgerTransaction.note` in `lib/features/transactions/domain/entities/ledger_transaction.dart`.
  - `TransactionModel.note` in `lib/features/transactions/data/models/transaction_model.dart`.
  - UI component: `TransactionNoteInput` in `lib/features/transactions/presentation/widgets/transaction_note_input.dart`.
  - Shared form wrapper: `TransactionEntryForm` in `lib/features/transactions/presentation/widgets/transaction_entry_form.dart`.
- User input locations:
  - Quick entry sheet: `lib/features/transactions/presentation/quick_entry_sheet.dart`.
  - Transaction editor: `lib/features/transactions/presentation/transaction_editor_body.dart`.
- Component combining note and audio:
  - `TransactionNoteInput` combines a text note `TextField` and microphone/recording controls in one input area.
  - It receives `TextEditingController noteController`, `AudioAttachmentModel? audio`, and `ValueChanged<AudioAttachmentModel?> onAudioChanged`.
- Note updates:
  - Note text is kept in `_noteCtrl` (`TextEditingController`) in quick entry/editor states.
  - Save trims note text and writes null when empty:
    - `note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()`
- Related files:
  - `lib/features/transactions/presentation/widgets/transaction_note_input.dart`
  - `lib/features/transactions/presentation/widgets/transaction_entry_form.dart`
  - `lib/features/transactions/presentation/quick_entry_sheet.dart`
  - `lib/features/transactions/presentation/transaction_editor_body.dart`
  - `lib/features/transactions/data/transaction_model_mapper.dart`

## 4. Transaction Model and Pending Logic

- Entity/model/DTO:
  - Domain entity: `lib/features/transactions/domain/entities/ledger_transaction.dart`
  - Storage model: `lib/features/transactions/data/models/transaction_model.dart`
  - Mapper: `lib/features/transactions/data/transaction_model_mapper.dart`
  - Repository contract: `lib/features/transactions/domain/repositories/ledger_repository.dart`
  - Repository implementation: `lib/features/transactions/data/sembast_ledger_repository.dart`
- Main transaction fields:
  - `id`: String
  - `title`: String
  - `amountVnd`: int
  - `isIncome`: bool
  - `categoryId`: String
  - `occurredAt`: DateTime
  - `pending`: bool
  - `complete`: bool
  - `note`: String?
  - `audio`: AudioAttachmentModel?
  - `images`: List<ImageAttachmentModel>
- Pending field exact name:
  - `pending`
- Pending logic:
  - Source of truth: `PendingReviewTransactionUseCase.isPendingReviewTransaction()` returns `transaction.pending`.
  - `LedgerQueryService.pendingInRange(...)` filters by `PendingReviewTransactionUseCase`.
  - Confirming pending calls `SembastLedgerRepository.confirmPending(id)`, which writes `pending: false` and `complete: true`.
- Where pending is set:
  - Quick entry: `_pending = widget.mode != QuickEntryMode.tap`; voice and receipt quick modes start pending.
  - Manual toggle: `TransactionPendingSwitch` in `TransactionEntryForm` consumers.
  - Editor: `_pending = e?.pending ?? widget.defaultPending`; save uses current `_pending`.
  - Demo/sample data: `DemoReviewDataService` and `populateJohnyData()`.
- New transaction flow:
  - FAB in `MainShell` calls `handleAddFab(...)` from `add_options_sheet.dart`.
  - `showQuickEntrySheet(...)` opens `_QuickEntryBody`.
  - `_save(...)` resolves a `TransactionSaveDraft`, then calls `LedgerRepository.addQuick(...)`.
  - `SembastLedgerRepository.addQuick(...)` creates `TransactionModel`, then writes through `putTransaction(...)`.
- Edit transaction flow:
  - `TransactionEditorBody` receives optional `existing`.
  - Existing fields populate local controllers/state.
  - Save calls `repo.putTransaction(existing.copyWith(...))` for edits or `repo.addQuick(...)` for new entries from editor context.
  - Delete flow asks confirmation and then calls repository delete.
- Review/pending flow:
  - `PendingScreen` in `lib/features/transactions/presentation/pending/pending_screen.dart`.
  - Controller: `lib/features/transactions/application/pending/pending_controller.dart`.
  - View model: `lib/features/transactions/application/pending/pending_view_model.dart`.
  - Attachment filter: `lib/features/transactions/application/pending/pending_attachment_filter.dart`.
  - Confirm helper: `lib/features/transactions/application/confirm_pending_flow.dart`.
- Mapper/toJson/fromJson/copyWith/equality:
  - `TransactionModel.toMap()` / `fromMap(...)` handles storage serialization.
  - `LedgerTransaction.copyWith(...)` handles domain copy.
  - `TransactionModel.copyWith(...)` handles storage copy.
  - No explicit equality/hashCode on `LedgerTransaction` or `TransactionModel`.
- Seed/demo/mock:
  - `lib/core/config/demo_seed.dart` (`populateJohnyData`)
  - `lib/features/settings/application/demo_review_data_service.dart`
  - `lib/core/seed/seed_assets.dart`
  - `lib/core/seed/seed_attachments.dart`
  - `lib/core/testing/fake_ledger_repository.dart`

## 5. Profile/Settings Screen

- Profile/settings screen:
  - `lib/features/settings/presentation/profile_screen.dart`
- Settings models/storage:
  - `UserPreferences`: `lib/features/settings/domain/user_preferences.dart`
  - `ReviewReminderSettings`: `lib/features/settings/domain/review_reminder_settings.dart`
  - `ThemeSettings`: `lib/app/theme/theme_settings.dart`
  - Controllers persist through SharedPreferences:
    - `lib/features/settings/application/user_preferences_controller.dart`
    - `lib/app/theme/theme_controller.dart`
- Toggle implementation style:
  - Uses `SwitchListTile.adaptive`.
  - Existing toggles include dark mode, colored surfaces, review reminder enabled, quick confirm pending.
- Good place for `AI nhan dien giong noi` toggle:
  - Best data place: add a bool to `UserPreferences`, because it is a user-facing feature preference and already persists locally.
  - Best UI place: Profile screen near transaction-entry preferences, likely around `_buildQuickConfirmTile(...)` or a new tile near "Them giao dich nhanh" / quick confirm area.
  - Avoid putting it inside theme settings or reminder settings.
- Persistence:
  - `UserPreferencesController` stores JSON string under key `userPreferences` in `SharedPreferences`.
- Related files:
  - `lib/features/settings/presentation/profile_screen.dart`
  - `lib/features/settings/domain/user_preferences.dart`
  - `lib/features/settings/application/user_preferences_controller.dart`
  - `test/features/settings/application/user_preferences_controller_test.dart`
  - `test/features/settings/presentation/profile_screen_test.dart`

## 6. API Client / Data Layer Pattern

- Existing API client:
  - Not found.
- Existing network/data pattern:
  - App is offline-first.
  - Data access goes through repository contracts and Riverpod providers.
  - Ledger persistence uses `LedgerRepository` with `SembastLedgerRepository`.
  - Platform-specific implementations use conditional exports, e.g. audio/image storage and notification platform.
- Error handling:
  - UI catches exceptions around save and shows `showError(...)` / `showInfo(...)` / `showSuccess(...)`.
  - Controllers often expose `AsyncValue` through Riverpod.
  - Recorder controller catches errors into `VoiceRecorderState.errorMessage`.
- Loading state:
  - Feature controllers commonly use `AsyncNotifierProvider.autoDispose`.
  - Widgets render `AsyncValue.when(...)` or local saving states.
- Dependency injection:
  - Riverpod providers in `lib/app/providers.dart` and feature-specific provider files.
  - Bootstrap overrides global providers.
- Suggested placement for `VoiceTransactionApiClient`:
  - Data layer: `lib/features/transactions/data/voice_transaction_api_client.dart`
  - Domain/application DTOs: `lib/features/transactions/application/voice_transaction_draft_parser.dart` or `lib/features/transactions/domain/entities/voice_transaction_draft.dart` depending on how much logic is shared.
  - Provider: either `lib/app/providers.dart` if app-wide config is needed, or near transactions application if feature-scoped.
  - Keep it out of UI widgets; UI should call a controller/action that wraps upload, parsing, loading/error state, and draft application.
- Related files:
  - `lib/app/providers.dart`
  - `lib/features/transactions/domain/repositories/ledger_repository.dart`
  - `lib/features/transactions/data/sembast_ledger_repository.dart`
  - `lib/features/transactions/application/transaction_draft_validator.dart`
  - `lib/features/transactions/presentation/widgets/transaction_note_input.dart`

## 7. Environment / Config

- Current env mechanism:
  - Not found.
- `--dart-define`:
  - Not found in code/docs.
- Flavor/dev/prod config:
  - Not found.
- Constants/config files:
  - `lib/core/constants/app_constants.dart`
  - `lib/core/config/demo_seed.dart`
  - These are not environment config mechanisms.
- Suggested `VOICE_TRANSACTION_API_BASE_URL` placement:
  - Add a small config object, e.g. `lib/core/config/app_environment.dart`, reading `String.fromEnvironment("VOICE_TRANSACTION_API_BASE_URL")`.
  - Provide it through Riverpod so tests can override it.
  - Keep default empty/disabled to avoid accidental network calls.
- Demo token:
  - Do not put `OPENAI_API_KEY` in Flutter.
  - A demo gate token can be placed in Flutter only if it is treated as non-secret and only protects casual demo access.
  - Prefer Render backend checks `DEMO_TOKEN` from environment and Flutter sends an optional `X-Demo-Token` supplied by `--dart-define` or omitted for local demo.
  - If the token has any real security value, do not ship it in the client.
- Related files:
  - `pubspec.yaml`
  - `lib/app/providers.dart`
  - `lib/core/constants/app_constants.dart`
  - `README.md`
  - `docs/development_guide.md`

## 8. Render Backend Placement

- Suggested folder:
  - `voice_demo_api/`
- Fit in repo:
  - Suitable as a small sibling folder to Flutter app code.
  - It will not conflict with Flutter if Render root directory is set to `voice_demo_api`.
  - Add backend-specific `.env.example` only; do not commit real `.env`.
- Suggested backend files:
  - `voice_demo_api/main.py`
  - `voice_demo_api/requirements.txt`
  - `voice_demo_api/.env.example`
  - `voice_demo_api/README.md`
- Render config proposal:
  - Root Directory: `voice_demo_api`
  - Build Command: `pip install -r requirements.txt`
  - Start Command: `uvicorn main:app --host 0.0.0.0 --port $PORT`
  - Environment Variables:
    - `OPENAI_API_KEY`: secret, Render only.
    - `DEMO_TOKEN`: optional shared demo gate.
    - `ALLOWED_ORIGINS`: deployed Flutter web origin(s), comma-separated.
    - `OPENAI_TRANSCRIBE_MODEL`: default `gpt-4o-mini-transcribe` or `gpt-4o-transcribe`.
    - `OPENAI_PARSE_MODEL`: choose a current text/structured-output model at implementation time.
- OpenAI docs note:
  - Official speech-to-text docs list `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`, and `gpt-4o-transcribe-diarize`; file uploads are limited to 25 MB and common accepted types include `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, and `webm`.
  - Relevant official docs:
    - https://platform.openai.com/docs/guides/speech-to-text
    - https://platform.openai.com/docs/api-reference/audio/createTranscription
    - https://platform.openai.com/docs/models/gpt-4o-transcribe

## 9. Suggested Backend Contract

Endpoint:

```text
POST /voice-transaction-demo
```

Request:

- Content type: `multipart/form-data`
- Audio field name: `audio`
- Form fields:
  - `locale`: default `vi-VN`
  - `timezone`: default app/device timezone, e.g. `Asia/Saigon`
- Header:
  - `X-Demo-Token`: optional for demo gate; do not confuse this with OpenAI API key.

Response:

```json
{
  "transcript": "an toi 85000 hom nay",
  "transactionDraft": {
    "title": "An toi",
    "amountVnd": 85000,
    "isIncome": false,
    "categoryName": "An uong",
    "categoryId": null,
    "note": "Parsed from voice transcript",
    "transactionDate": "2026-05-24T19:30:00+07:00",
    "pending": true,
    "confidence": 0.82
  },
  "warnings": [
    "category_unresolved"
  ]
}
```

Mapping to current app model:

- `transactionDraft.amountVnd` -> `LedgerTransaction.amountVnd` / `TransactionModel.amountVnd`.
- `transactionDraft.isIncome` or `type` -> `LedgerTransaction.isIncome`.
- `transactionDraft.categoryId` -> `LedgerTransaction.categoryId` when backend can map to an existing ID.
- `transactionDraft.categoryName` -> should be resolved client-side against current `LedgerCategory` list if `categoryId` is null.
- `transactionDraft.note` -> `LedgerTransaction.note`.
- `transactionDraft.transactionDate` -> `LedgerTransaction.occurredAt`.
- `transactionDraft.pending` -> `LedgerTransaction.pending`.
- Suggested default: AI-created voice transaction should remain `pending: true` until user reviews it, because current business rule says pending is the source of truth for review.
- `complete` should be computed client-side using current `TransactionDraftResolver` / `TransactionDraftValidator` rather than trusted directly from backend.

Important contract note:

- Backend should not return OpenAI raw secrets or internal prompts.
- Backend should return warnings instead of throwing for partial parsing, e.g. `amount_missing`, `date_uncertain`, `category_unresolved`.

## 10. Implementation Plan Draft

### Prompt 1: Render Backend

Ask Cursor to:

- Create `voice_demo_api/`.
- Implement FastAPI app in `main.py`.
- Add endpoints:
  - `GET /health`
  - `POST /voice-transaction-demo`
- Accept multipart `audio`, `locale`, `timezone`, optional `X-Demo-Token`.
- Validate file size and extension/mime before sending to OpenAI.
- Use `OPENAI_API_KEY` from environment only.
- Use OpenAI transcription endpoint with a transcribe model such as `gpt-4o-mini-transcribe` or `gpt-4o-transcribe`.
- Parse transcript into a transaction draft using structured JSON output.
- Return `{ transcript, transactionDraft, warnings }`.
- Add CORS using `ALLOWED_ORIGINS`.
- Add `requirements.txt`, `.env.example`, and backend README.
- Include local run instructions and curl examples.
- Do not include real secrets.

### Prompt 2: Flutter Toggle + API Client

Ask Cursor to:

- Add an `aiVoiceRecognitionEnabled` bool to `UserPreferences`.
- Update `copyWith`, `toJson`, `fromJson`, equality/hashCode, and tests.
- Add a `SwitchListTile.adaptive` in `ProfileScreen` near transaction-entry preferences.
- Add environment config for `VOICE_TRANSACTION_API_BASE_URL` using `String.fromEnvironment`.
- Add an API client in the transactions data/application layer.
- Add multipart upload support. This likely requires adding `http` or another small client dependency, because no HTTP package exists now.
- Keep `OPENAI_API_KEY` out of Flutter.
- Integrate with voice completion flow only when toggle is enabled and base URL is configured.
- On successful parse, prefill amount/type/category/date/note while keeping transaction pending by default.
- Preserve current manual voice-note behavior if AI is off, backend fails, or parsing is uncertain.
- Add tests for preferences serialization, disabled toggle behavior, and draft mapping.
- Run `flutter analyze`, `flutter test`, and a web build.

## 11. Risks and Questions

Technical risks:

- Web audio temporary path handling currently reads bytes through `html.HttpRequest.request(path)`; verify the recorded path/blob remains accessible when also uploading.
- No HTTP client dependency currently exists, so Flutter implementation will need a new dependency or a lower-level client approach.
- CORS must be configured on Render for Flutter Web/PWA.
- File uploads to OpenAI have size/type limits; app currently allows up to 3 minutes recording by default.
- Current audio encoders include `.opus`, but OpenAI speech-to-text accepted upload list from docs includes `mp3`, `mp4`, `mpeg`, `mpga`, `m4a`, `wav`, `webm`; confirm whether `.opus` should be converted or avoided.
- Backend parsing category IDs is tricky because category IDs are local/generated. Safer: backend returns `categoryName`/type and Flutter resolves locally.
- Vietnamese text/date/amount parsing may be ambiguous and should produce warnings.
- Client-side demo token is not a real secret.

Files likely affected later:

- `pubspec.yaml`
- `lib/features/settings/domain/user_preferences.dart`
- `lib/features/settings/application/user_preferences_controller.dart`
- `lib/features/settings/presentation/profile_screen.dart`
- `lib/features/transactions/presentation/widgets/transaction_note_input.dart`
- `lib/features/transactions/presentation/quick_entry_sheet.dart`
- `lib/features/transactions/presentation/transaction_editor_body.dart`
- `lib/features/transactions/application/transaction_draft_validator.dart`
- `lib/app/providers.dart`
- New client/config files under `lib/core/config` and/or `lib/features/transactions/data`
- Tests under `test/features/settings` and `test/features/transactions`

Uncertain points:

- Whether AI parsing should auto-fill the current open form or create a new pending transaction directly.
- Whether the voice recording should still be saved as an attachment after AI parses it.
- Whether AI should be available on Web only, Android only, or both.
- Whether backend should use `gpt-4o-mini-transcribe` for cost or `gpt-4o-transcribe` for quality.
- Whether parsed date should default to now, today, or require user confirmation when omitted.
- Whether category matching should be strict or fallback to `Khac`.

Questions to confirm before implementation:

- Should AI voice create a pending transaction immediately, or only prefill the sheet for user confirmation?
- Should original audio be retained as `audio` attachment after AI parsing?
- Is `AI nhan dien giong noi` default off?
- What Render URL/domain will Flutter call?
- Is a demo token needed, and is it acceptable as a non-secret client-side gate?
- Which model priority: lower cost or best transcription quality?
- Should backend parse category by Vietnamese name only, or should Flutter send current categories to backend?

## 12. Verification Commands

Flutter:

```bash
flutter pub get
dart format .
flutter analyze
flutter test
flutter build web --release --pwa-strategy=none
flutter build apk --debug
```

Backend local run:

```bash
cd voice_demo_api
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
uvicorn main:app --reload --host 127.0.0.1 --port 8000
```

Backend health check:

```bash
curl http://127.0.0.1:8000/health
```

Test upload audio sample:

```bash
curl -X POST http://127.0.0.1:8000/voice-transaction-demo ^
  -H "X-Demo-Token: <demo-token-if-enabled>" ^
  -F "audio=@assets/seed/audio/voice_note.mp3" ^
  -F "locale=vi-VN" ^
  -F "timezone=Asia/Saigon"
```

Render smoke test:

```bash
curl https://<render-service>.onrender.com/health
```

