import "dart:async";

import "package:record/record.dart";

import "../../../core/audio_storage_helper.dart";
import "../domain/voice_note_model.dart";
import "audio_storage_service.dart";
import "voice_note_file_service.dart";

class VoiceRecorderService {
  VoiceRecorderService({AudioRecorder? recorder, AudioStorageService? storage})
    : _recorder = recorder ?? AudioRecorder(),
      _storage = storage ?? AudioStorageService();

  final AudioRecorder _recorder;
  final AudioStorageService _storage;
  RecordConfig? _config;
  String? _extension;
  DateTime? _startedAt;
  Duration _recordedBeforePause = Duration.zero;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    final permitted = await hasPermission();
    if (!permitted) {
      throw StateError(
        "Không thể truy cập micro. Vui lòng kiểm tra quyền truy cập.",
      );
    }

    final encoder = await _bestEncoder();
    final extension = _extensionForEncoder(encoder);
    _extension = extension;
    final path = await VoiceNoteFileService.temporaryRecordingPath(extension);
    _config = RecordConfig(
      encoder: encoder,
      sampleRate: 44100,
      numChannels: 1,
      bitRate: 128000,
    );
    _recordedBeforePause = Duration.zero;
    await _recorder.start(_config!, path: path);
    _startedAt = DateTime.now();
  }

  Future<void> pause() async {
    final startedAt = _startedAt;
    if (startedAt != null) {
      _recordedBeforePause += DateTime.now().difference(startedAt);
    }
    _startedAt = null;
    await _recorder.pause();
  }

  Future<void> resume() async {
    await _recorder.resume();
    _startedAt = DateTime.now();
  }

  Future<void> cancel() async {
    _startedAt = null;
    _recordedBeforePause = Duration.zero;
    await _recorder.cancel();
  }

  Future<VoiceNoteModel> stop() async {
    final duration = elapsed;
    final path = await _recorder.stop();
    _startedAt = null;
    _recordedBeforePause = Duration.zero;

    if (path == null || path.isEmpty) {
      throw StateError("Không có file ghi âm. Vui lòng thử lại.");
    }

    final bytes = await VoiceNoteFileService.readRecordingBytes(path);
    if (bytes.isEmpty) {
      throw StateError("Bản ghi đang trống. Vui lòng ghi lại.");
    }

    final audio = await _storage.saveRecording(
      bytes: bytes,
      duration: duration,
      mimeType: AudioStorageHelper.contentTypeForBytes(bytes),
      extension: _extension ?? AudioStorageHelper.extensionForBytes(bytes),
    );
    return VoiceNoteModel(audio: audio, duration: duration);
  }

  Duration get elapsed {
    final startedAt = _startedAt;
    if (startedAt == null) return _recordedBeforePause;
    return _recordedBeforePause + DateTime.now().difference(startedAt);
  }

  Future<void> dispose() => _recorder.dispose();

  Future<AudioEncoder> _bestEncoder() async {
    const candidates = [
      AudioEncoder.aacLc,
      AudioEncoder.opus,
      AudioEncoder.wav,
    ];
    for (final encoder in candidates) {
      if (await _recorder.isEncoderSupported(encoder)) return encoder;
    }
    return AudioEncoder.aacLc;
  }

  String _extensionForEncoder(AudioEncoder encoder) {
    return switch (encoder) {
      AudioEncoder.wav => ".wav",
      AudioEncoder.aacLc => ".m4a",
      AudioEncoder.opus => ".opus",
      _ => ".m4a",
    };
  }
}
