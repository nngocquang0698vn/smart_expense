import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/transactions/application/voice_note/voice_recorder_config.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_note_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_recording_status.dart";
import "package:smart_expense/features/transactions/domain/repositories/voice_recorder_repository.dart";

final voiceRecorderControllerProvider = NotifierProvider.autoDispose
    .family<VoiceRecorderController, VoiceRecorderState, VoiceRecorderConfig>(
      VoiceRecorderController.new,
    );

const Object _unchanged = _Unchanged();

class _Unchanged {
  const _Unchanged();
}

class VoiceRecorderState {
  const VoiceRecorderState({
    this.status = VoiceRecordingStatus.idle,
    this.voiceNote,
    this.elapsed = Duration.zero,
    this.errorMessage,
  });

  final VoiceRecordingStatus status;
  final VoiceNoteModel? voiceNote;
  final Duration elapsed;
  final String? errorMessage;

  bool get canRecord =>
      status == VoiceRecordingStatus.idle ||
      status == VoiceRecordingStatus.preview ||
      status == VoiceRecordingStatus.saved ||
      status == VoiceRecordingStatus.error;

  VoiceRecorderState copyWith({
    VoiceRecordingStatus? status,
    Object? voiceNote = _unchanged,
    Duration? elapsed,
    Object? errorMessage = _unchanged,
  }) {
    return VoiceRecorderState(
      status: status ?? this.status,
      voiceNote: identical(voiceNote, _unchanged)
          ? this.voiceNote
          : voiceNote as VoiceNoteModel?,
      elapsed: elapsed ?? this.elapsed,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

class VoiceRecorderController extends Notifier<VoiceRecorderState> {
  VoiceRecorderController(this._config);

  final VoiceRecorderConfig _config;
  late final VoiceRecorderRepository _recorder;
  Timer? _ticker;

  @override
  VoiceRecorderState build() {
    _recorder = ref.watch(voiceRecorderRepositoryProvider(_config));
    ref.onDispose(() {
      _ticker?.cancel();
    });
    return const VoiceRecorderState();
  }

  Future<void> start() async {
    if (!state.canRecord) return;
    state = state.copyWith(
      status: VoiceRecordingStatus.recording,
      voiceNote: null,
      errorMessage: null,
      elapsed: Duration.zero,
    );
    try {
      await _recorder.start();
      _startTicker();
    } catch (e) {
      _fail(_friendlyError(e, fallback: "KhÃ´ng thá»ƒ báº¯t Ä‘áº§u ghi Ã¢m."));
    }
  }

  Future<void> pause() async {
    if (state.status != VoiceRecordingStatus.recording) return;
    try {
      await _recorder.pause();
      _ticker?.cancel();
      state = state.copyWith(
        status: VoiceRecordingStatus.paused,
        elapsed: _recorder.elapsed,
      );
    } catch (e) {
      _fail(_friendlyError(e, fallback: "KhÃ´ng thá»ƒ táº¡m dá»«ng ghi Ã¢m."));
    }
  }

  Future<void> resume() async {
    if (state.status != VoiceRecordingStatus.paused) return;
    try {
      await _recorder.resume();
      state = state.copyWith(status: VoiceRecordingStatus.recording);
      _startTicker();
    } catch (e) {
      _fail(_friendlyError(e, fallback: "KhÃ´ng thá»ƒ tiáº¿p tá»¥c ghi Ã¢m."));
    }
  }

  Future<void> cancel() async {
    try {
      await _recorder.cancel();
    } catch (_) {
      // The UI can return to idle even if the recorder was already stopped.
    }
    _ticker?.cancel();
    state = state.copyWith(
      status: VoiceRecordingStatus.idle,
      voiceNote: null,
      elapsed: Duration.zero,
      errorMessage: "ÄÃ£ huá»· ghi Ã¢m.",
    );
  }

  Future<VoiceNoteModel?> finish() async {
    if (state.status != VoiceRecordingStatus.recording &&
        state.status != VoiceRecordingStatus.paused) {
      return state.voiceNote;
    }
    _ticker?.cancel();
    state = state.copyWith(status: VoiceRecordingStatus.saving);
    try {
      final note = await _recorder.stop();
      state = state.copyWith(
        status: VoiceRecordingStatus.preview,
        voiceNote: note,
        elapsed: note.duration,
      );
      return note;
    } catch (e) {
      _fail(_friendlyError(e, fallback: "KhÃ´ng thá»ƒ lÆ°u báº£n ghi."));
      return null;
    }
  }

  void useExisting(AudioAttachmentModel audio) {
    state = state.copyWith(
      status: VoiceRecordingStatus.preview,
      voiceNote: VoiceNoteModel(audio: audio, duration: audio.duration),
      errorMessage: null,
    );
  }

  void confirm() {
    if (state.voiceNote == null) return;
    state = state.copyWith(status: VoiceRecordingStatus.saved);
  }

  void remove() {
    state = state.copyWith(
      status: VoiceRecordingStatus.idle,
      voiceNote: null,
      elapsed: Duration.zero,
      errorMessage: null,
    );
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      final elapsed = _recorder.elapsed;
      if (elapsed >= _config.maxDuration) {
        unawaited(finish());
      } else {
        state = state.copyWith(elapsed: elapsed);
      }
    });
  }

  void _fail(String message) {
    _ticker?.cancel();
    state = state.copyWith(
      status: VoiceRecordingStatus.error,
      errorMessage: message,
    );
  }

  String _friendlyError(Object error, {required String fallback}) {
    final text = error
        .toString()
        .replaceFirst("StateError: ", "")
        .replaceFirst("Exception: ", "");
    if (text.toLowerCase().contains("permission") ||
        text.toLowerCase().contains("micro")) {
      return "KhÃ´ng thá»ƒ truy cáº­p micro. Vui lÃ²ng kiá»ƒm tra quyá»n truy cáº­p.";
    }
    return text.trim().isEmpty ? fallback : text;
  }
}
