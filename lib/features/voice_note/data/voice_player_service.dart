import "dart:async";
import "dart:convert";

import "package:just_audio/just_audio.dart";

import "../../../core/audio_storage_helper.dart";
import "voice_playback_source_service.dart";

class VoicePlayerService {
  VoicePlayerService({AudioPlayer? player}) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  VoicePlaybackSource? _source;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Duration get position => _player.position;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;

  Future<void> loadBase64(String audioBase64) async {
    final bytes = base64Decode(audioBase64);
    if (bytes.isEmpty) {
      throw StateError("File ghi âm đang trống.");
    }

    await VoicePlaybackSourceService.release(_source);
    _source = await VoicePlaybackSourceService.create(
      bytes,
      contentType: AudioStorageHelper.contentTypeForBytes(bytes),
    );

    final source = _source!;
    if (source.isFile) {
      await _player.setFilePath(source.value);
    } else {
      await _player.setUrl(source.value);
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> dispose() async {
    await _player.dispose();
    await VoicePlaybackSourceService.release(_source);
  }
}
