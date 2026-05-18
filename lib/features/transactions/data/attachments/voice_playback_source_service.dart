import "package:smart_expense/features/transactions/data/attachments/voice_playback_source_service_io.dart"
    if (dart.library.html) "package:smart_expense/features/transactions/data/attachments/voice_playback_source_service_web.dart";

class VoicePlaybackSource {
  const VoicePlaybackSource.file(this.value) : isFile = true;
  const VoicePlaybackSource.url(this.value) : isFile = false;

  final String value;
  final bool isFile;
}

abstract final class VoicePlaybackSourceService {
  static Future<VoicePlaybackSource> create(
    List<int> bytes, {
    required String contentType,
  }) {
    return createVoicePlaybackSource(bytes, contentType: contentType);
  }

  static Future<void> release(VoicePlaybackSource? source) {
    return releaseVoicePlaybackSource(source);
  }
}
