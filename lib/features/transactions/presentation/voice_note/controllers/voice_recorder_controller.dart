import "dart:async";

import "package:flutter/foundation.dart";

import "package:smart_expense/features/transactions/data/attachments/voice_recorder_service.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_note_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/voice_recording_status.dart";

class VoiceRecorderController extends ChangeNotifier {
  VoiceRecorderController({
    VoiceRecorderService? recorderService,
    Duration maxDuration = const Duration(minutes: 3),
  }) : _recorderService = recorderService ?? VoiceRecorderService(),
       _maxDuration = maxDuration;

  final VoiceRecorderService _recorderService;
  final Duration _maxDuration;
  Timer? _ticker;

  VoiceRecordingStatus status = VoiceRecordingStatus.idle;
  VoiceNoteModel? voiceNote;
  Duration elapsed = Duration.zero;
  String? errorMessage;

  bool get canRecord =>
      status == VoiceRecordingStatus.idle ||
      status == VoiceRecordingStatus.preview ||
      status == VoiceRecordingStatus.saved ||
      status == VoiceRecordingStatus.error;

  Future<void> start() async {
    if (!canRecord) return;
    _setStatus(VoiceRecordingStatus.recording);
    voiceNote = null;
    errorMessage = null;
    elapsed = Duration.zero;
    try {
      await _recorderService.start();
      _startTicker();
    } catch (e) {
      _fail(_friendlyError(e, fallback: "Không thể bắt đầu ghi âm."));
    }
  }

  Future<void> pause() async {
    if (status != VoiceRecordingStatus.recording) return;
    try {
      await _recorderService.pause();
      _ticker?.cancel();
      elapsed = _recorderService.elapsed;
      _setStatus(VoiceRecordingStatus.paused);
    } catch (e) {
      _fail(_friendlyError(e, fallback: "Không thể tạm dừng ghi âm."));
    }
  }

  Future<void> resume() async {
    if (status != VoiceRecordingStatus.paused) return;
    try {
      await _recorderService.resume();
      _setStatus(VoiceRecordingStatus.recording);
      _startTicker();
    } catch (e) {
      _fail(_friendlyError(e, fallback: "Không thể tiếp tục ghi âm."));
    }
  }

  Future<void> cancel() async {
    try {
      await _recorderService.cancel();
    } catch (_) {
      // Nothing useful to recover here; the UI can return to idle.
    }
    _ticker?.cancel();
    voiceNote = null;
    elapsed = Duration.zero;
    errorMessage = "Đã huỷ ghi âm.";
    _setStatus(VoiceRecordingStatus.idle);
  }

  Future<VoiceNoteModel?> finish() async {
    if (status != VoiceRecordingStatus.recording &&
        status != VoiceRecordingStatus.paused) {
      return voiceNote;
    }
    _ticker?.cancel();
    _setStatus(VoiceRecordingStatus.saving);
    try {
      final note = await _recorderService.stop();
      voiceNote = note;
      elapsed = note.duration;
      _setStatus(VoiceRecordingStatus.preview);
      return note;
    } catch (e) {
      _fail(_friendlyError(e, fallback: "Không thể lưu bản ghi."));
      return null;
    }
  }

  void useExisting(AudioAttachmentModel audio) {
    voiceNote = VoiceNoteModel(audio: audio, duration: audio.duration);
    status = VoiceRecordingStatus.preview;
    errorMessage = null;
    notifyListeners();
  }

  void confirm() {
    if (voiceNote == null) return;
    _setStatus(VoiceRecordingStatus.saved);
  }

  void remove() {
    voiceNote = null;
    elapsed = Duration.zero;
    errorMessage = null;
    _setStatus(VoiceRecordingStatus.idle);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _recorderService.dispose();
    super.dispose();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
      elapsed = _recorderService.elapsed;
      if (elapsed >= _maxDuration) {
        unawaited(finish());
      } else {
        notifyListeners();
      }
    });
  }

  void _setStatus(VoiceRecordingStatus value) {
    status = value;
    notifyListeners();
  }

  void _fail(String message) {
    _ticker?.cancel();
    errorMessage = message;
    status = VoiceRecordingStatus.error;
    notifyListeners();
  }

  String _friendlyError(Object error, {required String fallback}) {
    final text = error
        .toString()
        .replaceFirst("StateError: ", "")
        .replaceFirst("Exception: ", "");
    if (text.toLowerCase().contains("permission") ||
        text.toLowerCase().contains("micro")) {
      return "Không thể truy cập micro. Vui lòng kiểm tra quyền truy cập.";
    }
    return text.trim().isEmpty ? fallback : text;
  }
}
