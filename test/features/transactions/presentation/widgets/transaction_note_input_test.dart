import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/app/localization/app_localizations.dart";
import "package:smart_expense/app/providers.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_note_model.dart";
import "package:smart_expense/features/transactions/domain/repositories/voice_recorder_repository.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/widgets/voice_note_player.dart";
import "package:smart_expense/features/transactions/presentation/widgets/transaction_note_input.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";

void main() {
  late _FakeVoiceRecorderRepository recorder;

  setUp(() {
    recorder = _FakeVoiceRecorderRepository();
  });

  Future<void> pumpNoteInput(
    WidgetTester tester, {
    required TextEditingController noteController,
    AudioAttachmentModel? audio,
    required ValueChanged<AudioAttachmentModel?> onAudioChanged,
    bool autoStartRecording = false,
    bool amountKeypadOpen = false,
    VoidCallback? onDismissAmountKeypad,
    double width = 360,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceRecorderRepositoryProvider.overrideWith(
            (ref, config) => recorder,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(
            const ThemeSettings(),
            brightness: Brightness.light,
          ),
          locale: const Locale("vi", "VN"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: TransactionNoteInput(
                  noteController: noteController,
                  audio: audio,
                  onAudioChanged: onAudioChanged,
                  autoStartRecording: autoStartRecording,
                  amountKeypadOpen: amountKeypadOpen,
                  onDismissAmountKeypad: onDismissAmountKeypad,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets("renders placeholder Ghi chú (tuỳ chọn)", (tester) async {
    final noteCtrl = TextEditingController();
    await pumpNoteInput(
      tester,
      noteController: noteCtrl,
      onAudioChanged: (_) {},
    );

    expect(find.text("Ghi chú (tuỳ chọn)"), findsOneWidget);
    expect(find.textContaining("Bấm micro"), findsOneWidget);
  });

  testWidgets("enters text note normally", (tester) async {
    final noteCtrl = TextEditingController();
    await pumpNoteInput(
      tester,
      noteController: noteCtrl,
      onAudioChanged: (_) {},
    );

    await tester.enterText(find.byType(TextField), "Ăn trưa với team");
    expect(noteCtrl.text, "Ăn trưa với team");
  });

  testWidgets("tap mic starts recording via repository", (tester) async {
    final noteCtrl = TextEditingController();
    await pumpNoteInput(
      tester,
      noteController: noteCtrl,
      onAudioChanged: (_) {},
    );

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump();

    expect(recorder.started, isTrue);
    expect(find.text("Đang ghi âm"), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });

  testWidgets("shows recording state when repository is active", (
    tester,
  ) async {
    final noteCtrl = TextEditingController();
    recorder.elapsed = const Duration(seconds: 18);
    await pumpNoteInput(
      tester,
      noteController: noteCtrl,
      onAudioChanged: (_) {},
    );

    await tester.tap(find.byIcon(Icons.mic_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.textContaining("00:"), findsWidgets);
    expect(find.text("Đang ghi âm"), findsOneWidget);
  });

  testWidgets("shows attached audio with playback player", (tester) async {
    final noteCtrl = TextEditingController();
    final audio = AudioAttachmentModel(
      id: "a1",
      durationMs: 18000,
      createdAt: DateTime(2026, 5, 19),
      mimeType: "audio/m4a",
      extension: ".m4a",
      fileSize: 128,
    );

    await pumpNoteInput(
      tester,
      noteController: noteCtrl,
      audio: audio,
      onAudioChanged: (_) {},
    );
    await tester.pump();
    await tester.pump();

    expect(find.text("Đã ghi âm"), findsOneWidget);
    expect(find.byType(VoiceNotePlayer), findsOneWidget);
  });

  testWidgets("clears stale audio preview when next transaction has no audio", (
    tester,
  ) async {
    final noteCtrl = TextEditingController();
    AudioAttachmentModel? audio = AudioAttachmentModel(
      id: "a1",
      durationMs: 18000,
      createdAt: DateTime(2026, 5, 19),
      mimeType: "audio/m4a",
      extension: ".m4a",
      fileSize: 128,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceRecorderRepositoryProvider.overrideWith(
            (ref, config) => recorder,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.build(
            const ThemeSettings(),
            brightness: Brightness.light,
          ),
          locale: const Locale("vi", "VN"),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    TextButton(
                      onPressed: () => setState(() => audio = null),
                      child: const Text("clear audio"),
                    ),
                    TransactionNoteInput(
                      noteController: noteCtrl,
                      audio: audio,
                      onAudioChanged: (_) {},
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(find.byType(VoiceNotePlayer), findsOneWidget);

    await tester.tap(find.text("clear audio"));
    await tester.pump();
    await tester.pump();

    expect(find.byType(VoiceNotePlayer), findsNothing);
  });

  testWidgets("hides voice helper while amount keypad is open", (tester) async {
    final noteCtrl = TextEditingController();
    await pumpNoteInput(
      tester,
      noteController: noteCtrl,
      onAudioChanged: (_) {},
      amountKeypadOpen: true,
    );

    expect(find.textContaining("Bấm micro"), findsNothing);
  });

  testWidgets("dismisses keypad callback when note tapped with keypad open", (
    tester,
  ) async {
    final noteCtrl = TextEditingController();
    var dismissed = false;

    await pumpNoteInput(
      tester,
      noteController: noteCtrl,
      onAudioChanged: (_) {},
      amountKeypadOpen: true,
      onDismissAmountKeypad: () => dismissed = true,
    );

    final noteField = find.byKey(const Key("transaction_note_field"));
    await tester.tap(noteField);
    await tester.pump();
    await tester.pump();

    expect(dismissed, isTrue);
  });

  testWidgets("layout does not overflow at narrow width", (tester) async {
    final noteCtrl = TextEditingController();
    await pumpNoteInput(
      tester,
      noteController: noteCtrl,
      onAudioChanged: (_) {},
      width: 280,
    );

    expect(tester.takeException(), isNull);
  });
}

class _FakeVoiceRecorderRepository implements VoiceRecorderRepository {
  bool started = false;

  @override
  Duration elapsed = Duration.zero;

  @override
  Future<void> start() async {
    started = true;
  }

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<VoiceNoteModel> stop() async {
    return VoiceNoteModel(
      audio: AudioAttachmentModel(
        id: "audio-1",
        durationMs: elapsed.inMilliseconds,
        createdAt: DateTime(2026, 5, 19),
        mimeType: "audio/m4a",
        extension: ".m4a",
        fileSize: 64,
      ),
      duration: elapsed,
    );
  }

  @override
  Future<void> dispose() async {}
}
