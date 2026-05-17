import "voice_note_file_service_io.dart"
    if (dart.library.html) "voice_note_file_service_web.dart";

abstract final class VoiceNoteFileService {
  static Future<String> temporaryRecordingPath(String extension) {
    return temporaryVoiceNotePath(extension);
  }

  static Future<List<int>> readRecordingBytes(String path) {
    return readVoiceNoteBytes(path);
  }
}
