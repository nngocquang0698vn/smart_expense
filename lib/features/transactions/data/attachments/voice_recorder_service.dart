import "dart:async";

import "package:flutter/foundation.dart";
import "package:record/record.dart";

import "package:smart_expense/features/transactions/domain/entities/attachments/voice_note_model.dart";
import "package:smart_expense/features/transactions/domain/repositories/voice_recorder_repository.dart";
import "package:smart_expense/features/transactions/data/attachments/audio_storage_service.dart";
import "package:smart_expense/features/transactions/data/attachments/voice_note_file_service.dart";

class VoiceRecorderService implements VoiceRecorderRepository {
  VoiceRecorderService({AudioRecorder? recorder, AudioStorageService? storage})
    : _recorder = recorder ?? AudioRecorder(),
      _storage = storage ?? AudioStorageService();

  static const _nativeBackendFormats = [
    _RecordingFormat(
      encoder: AudioEncoder.aacLc,
      extension: ".m4a",
      mimeType: "audio/m4a",
    ),
    _RecordingFormat(
      encoder: AudioEncoder.wav,
      extension: ".wav",
      mimeType: "audio/wav",
    ),
  ];

  static const _nativeLastChanceFormats = [
    _RecordingFormat(
      encoder: AudioEncoder.aacHe,
      extension: ".m4a",
      mimeType: "audio/m4a",
    ),
    _RecordingFormat(
      encoder: AudioEncoder.aacEld,
      extension: ".m4a",
      mimeType: "audio/m4a",
    ),
    _RecordingFormat(
      encoder: AudioEncoder.opus,
      extension: ".opus",
      mimeType: "audio/ogg",
    ),
    _RecordingFormat(
      encoder: AudioEncoder.flac,
      extension: ".flac",
      mimeType: "audio/flac",
    ),
  ];

  static const _webBackendFormats = [
    _RecordingFormat(
      encoder: AudioEncoder.aacLc,
      extension: ".m4a",
      mimeType: "audio/m4a",
    ),
    _RecordingFormat(
      encoder: AudioEncoder.opus,
      extension: ".webm",
      mimeType: "audio/webm",
    ),
    _RecordingFormat(
      encoder: AudioEncoder.wav,
      extension: ".wav",
      mimeType: "audio/wav",
    ),
  ];

  static const _webLastChanceFormats = [
    _RecordingFormat(
      encoder: AudioEncoder.pcm16bits,
      extension: ".pcm",
      mimeType: "audio/pcm",
    ),
  ];

  final AudioRecorder _recorder;
  final AudioStorageService _storage;
  RecordConfig? _config;
  _RecordingFormat? _format;
  DateTime? _startedAt;
  Duration _recordedBeforePause = Duration.zero;

  Future<bool> hasPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    final permitted = await hasPermission();
    if (!permitted) {
      throw StateError(
        "Không thể truy cập micro. Vui lòng kiểm tra quyền truy cập.",
      );
    }

    final format = await _bestSupportedFormat();

    final path = await VoiceNoteFileService.temporaryRecordingPath(
      format.extension,
    );
    _config = RecordConfig(
      encoder: format.encoder,
      sampleRate: 44100,
      numChannels: 1,
      bitRate: 128000,
    );
    _format = format;
    _recordedBeforePause = Duration.zero;
    await _recorder.start(_config!, path: path);
    _startedAt = DateTime.now();
  }

  @override
  Future<void> pause() async {
    final startedAt = _startedAt;
    if (startedAt != null) {
      _recordedBeforePause += DateTime.now().difference(startedAt);
    }
    _startedAt = null;
    await _recorder.pause();
  }

  @override
  Future<void> resume() async {
    await _recorder.resume();
    _startedAt = DateTime.now();
  }

  @override
  Future<void> cancel() async {
    _startedAt = null;
    _recordedBeforePause = Duration.zero;
    await _recorder.cancel();
  }

  @override
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

    final format = _format ?? _candidateFormats.first;
    final audio = await _storage.saveRecording(
      bytes: bytes,
      duration: duration,
      mimeType: format.mimeType,
      extension: format.extension,
    );
    return VoiceNoteModel(audio: audio, duration: duration);
  }

  @override
  Duration get elapsed {
    final startedAt = _startedAt;
    if (startedAt == null) return _recordedBeforePause;
    return _recordedBeforePause + DateTime.now().difference(startedAt);
  }

  @override
  Future<void> dispose() => _recorder.dispose();

  Future<_RecordingFormat> _bestSupportedFormat() async {
    for (final format in _candidateFormats) {
      if (await _recorder.isEncoderSupported(format.encoder)) {
        return format;
      }
    }
    return _candidateFormats.first;
  }

  List<_RecordingFormat> get _candidateFormats =>
      kIsWeb ? _webCandidateFormats : _nativeCandidateFormats;

  List<_RecordingFormat> get _nativeCandidateFormats => [
    ..._nativeBackendFormats,
    ..._nativeLastChanceFormats,
  ];

  List<_RecordingFormat> get _webCandidateFormats => [
    ..._webBackendFormats,
    ..._webLastChanceFormats,
  ];
}

class _RecordingFormat {
  const _RecordingFormat({
    required this.encoder,
    required this.extension,
    required this.mimeType,
  });

  final AudioEncoder encoder;
  final String extension;
  final String mimeType;
}
