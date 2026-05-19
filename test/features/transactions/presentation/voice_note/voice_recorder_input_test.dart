import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/app/theme/theme_settings.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_note_model.dart";
import "package:smart_expense/features/transactions/domain/repositories/voice_recorder_repository.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/widgets/voice_note_preview.dart";
import "package:smart_expense/features/transactions/presentation/voice_note/widgets/voice_recorder_input.dart";
import "package:smart_expense/shared/design_system/theme/app_theme.dart";

void main() {
  late _FakeVoiceRecorderRepository recorder;

  setUp(() {
    recorder = _FakeVoiceRecorderRepository();
  });

  Future<void> pumpInput(
    WidgetTester tester, {
    AudioAttachmentModel? audio,
    bool autoStartRecording = false,
    required ValueChanged<AudioAttachmentModel?> onChanged,
  }) {
    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          voiceRecorderRepositoryProvider.overrideWith((ref, config) {
            return recorder;
          }),
        ],
        child: MaterialApp(
          theme: AppTheme.build(
            const ThemeSettings(),
            brightness: Brightness.light,
          ),
          home: Scaffold(
            body: VoiceRecorderInput(
              audio: audio,
              autoStartRecording: autoStartRecording,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    "mounting with existing audio does not modify provider during build",
    (tester) async {
      final existing = _sampleAudio(id: "existing-1");
      final errors = <Object>[];

      final previousOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errors.add(details.exception);
        previousOnError?.call(details);
      };
      addTearDown(() => FlutterError.onError = previousOnError);

      await pumpInput(tester, audio: existing, onChanged: (_) {});
      await tester.pump();
      await tester.pump();

      expect(
        errors.where(
          (error) =>
              error.toString().contains(
                "Tried to modify a provider while the widget tree was building",
              ),
        ),
        isEmpty,
      );
    },
  );

  testWidgets("syncs existing audio to preview after post-frame callback", (
    tester,
  ) async {
    final existing = _sampleAudio(id: "existing-1");

    await pumpInput(tester, audio: existing, onChanged: (_) {});
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(VoiceNotePreview), findsOneWidget);
  });

  testWidgets("autoStartRecording starts after first frame", (tester) async {
    await pumpInput(
      tester,
      autoStartRecording: true,
      onChanged: (_) {},
    );
    await tester.pump();

    expect(find.byKey(const ValueKey("recording")), findsOneWidget);
    expect(recorder.started, isTrue);
  });

  testWidgets("didUpdateWidget syncs audio when prop changes after mount", (
    tester,
  ) async {
    final existing = _sampleAudio(id: "late-audio");

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
          home: Scaffold(body: _AudioHarness(audio: null)),
        ),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey("idle")), findsOneWidget);

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
          home: Scaffold(body: _AudioHarness(audio: existing)),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(VoiceNotePreview), findsOneWidget);
  });
}

class _AudioHarness extends StatefulWidget {
  const _AudioHarness({required this.audio});

  final AudioAttachmentModel? audio;

  @override
  State<_AudioHarness> createState() => _AudioHarnessState();
}

class _AudioHarnessState extends State<_AudioHarness> {
  @override
  Widget build(BuildContext context) {
    return VoiceRecorderInput(
      audio: widget.audio,
      onChanged: (_) {},
    );
  }
}

AudioAttachmentModel _sampleAudio({required String id}) {
  return AudioAttachmentModel(
    id: id,
    durationMs: 4500,
    createdAt: DateTime(2026, 5, 19),
    mimeType: "audio/m4a",
    extension: ".m4a",
    fileSize: 128,
  );
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
      audio: _sampleAudio(id: "audio-1"),
      duration: elapsed,
    );
  }

  @override
  Future<void> dispose() async {}
}
