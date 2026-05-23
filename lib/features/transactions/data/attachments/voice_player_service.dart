import "dart:async";

import "package:just_audio/just_audio.dart";

import "package:smart_expense/core/storage/audio_storage_helper.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/data/attachments/audio_storage_service.dart";
import "package:smart_expense/features/transactions/data/attachments/voice_playback_source_service.dart";

class VoicePlayerService {
  VoicePlayerService({AudioPlayer? player, AudioStorageService? storage})
    : _player = player ?? AudioPlayer(),
      _storage = storage ?? AudioStorageService();

  final AudioPlayer _player;
  final AudioStorageService _storage;
  VoicePlaybackSource? _source;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;

  Future<void> load(AudioAttachmentModel audio) async {
    final bytes = await _storage.read(audio);
    if (bytes.isEmpty) {
      throw StateError("File ghi âm đang trống.");
    }

    await VoicePlaybackSourceService.release(_source);
    _source = await VoicePlaybackSourceService.create(
      bytes,
      contentType: _playbackContentType(audio, bytes),
    );

    final source = _source!;
    if (source.isFile) {
      await _player.setFilePath(source.value);
    } else {
      await _player.setUrl(source.value);
    }
  }

  Future<void> reset() async {
    final source = _source;
    _source = null;
    await _player.stop();
    await VoicePlaybackSourceService.release(source);
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() async {
    await _player.dispose();
    await VoicePlaybackSourceService.release(_source);
  }

  String _playbackContentType(AudioAttachmentModel audio, List<int> bytes) {
    final mime = audio.mimeType.trim();
    if (mime.isNotEmpty && mime != "audio/*") return mime;
    return AudioStorageHelper.contentTypeForBytes(bytes);
  }
}
