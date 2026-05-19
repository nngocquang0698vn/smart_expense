import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:flutter_test/flutter_test.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/application/voice_note/voice_recorder_config.dart";
import "package:smart_expense/features/transactions/application/voice_note/voice_recorder_controller.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_note_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_recording_status.dart";
import "package:smart_expense/features/transactions/domain/repositories/voice_recorder_repository.dart";

void main() {
  late _FakeVoiceRecorderRepository recorder;
  late ProviderContainer container;
  late VoiceRecorderConfig config;
  late ProviderSubscription<VoiceRecorderState> subscription;

  setUp(() {
    recorder = _FakeVoiceRecorderRepository();
    config = VoiceRecorderConfig(
      sessionId: Object(),
      maxDuration: const Duration(minutes: 3),
    );
    container = ProviderContainer(
      overrides: [
        voiceRecorderRepositoryProvider.overrideWith((ref, config) => recorder),
      ],
    );
    subscription = container.listen(
      voiceRecorderControllerProvider(config),
      (_, _) {},
    );
  });

  tearDown(() {
    subscription.close();
    container.dispose();
  });

  test("start and finish create a preview note", () async {
    final controller = container.read(
      voiceRecorderControllerProvider(config).notifier,
    );

    await controller.start();
    expect(
      container.read(voiceRecorderControllerProvider(config)).status,
      VoiceRecordingStatus.recording,
    );

    final note = await controller.finish();
    final state = container.read(voiceRecorderControllerProvider(config));

    expect(note, isNotNull);
    expect(state.status, VoiceRecordingStatus.preview);
    expect(state.voiceNote?.audio.id, "audio-1");
    expect(recorder.started, isTrue);
    expect(recorder.stopped, isTrue);
  });

  test("pause and resume preserve elapsed state", () async {
    final controller = container.read(
      voiceRecorderControllerProvider(config).notifier,
    );

    await controller.start();
    recorder.elapsed = const Duration(seconds: 12);
    await controller.pause();
    expect(
      container.read(voiceRecorderControllerProvider(config)).elapsed,
      const Duration(seconds: 12),
    );

    await controller.resume();
    expect(
      container.read(voiceRecorderControllerProvider(config)).status,
      VoiceRecordingStatus.recording,
    );
  });

  test("recording failures move to error state", () async {
    recorder.startError = StateError("permission denied");
    final controller = container.read(
      voiceRecorderControllerProvider(config).notifier,
    );

    await controller.start();
    final state = container.read(voiceRecorderControllerProvider(config));

    expect(state.status, VoiceRecordingStatus.error);
    expect(state.errorMessage, contains("micro"));
  });
}

class _FakeVoiceRecorderRepository implements VoiceRecorderRepository {
  bool started = false;
  bool stopped = false;
  Object? startError;

  @override
  Duration elapsed = const Duration(seconds: 9);

  @override
  Future<void> start() async {
    final error = startError;
    if (error != null) throw error;
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
    stopped = true;
    return VoiceNoteModel(
      audio: AudioAttachmentModel(
        id: "audio-1",
        durationMs: elapsed.inMilliseconds,
        createdAt: DateTime(2026),
        mimeType: "audio/m4a",
        extension: ".m4a",
        fileSize: 42,
      ),
      duration: elapsed,
    );
  }

  @override
  Future<void> dispose() async {}
}
