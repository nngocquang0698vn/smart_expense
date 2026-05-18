import "package:smart_expense/features/transactions/data/attachments/voice_note_file_service_io.dart"
    if (dart.library.html) "package:smart_expense/features/transactions/data/attachments/voice_note_file_service_web.dart";

abstract final class VoiceNoteFileService {
  static Future<String> temporaryRecordingPath(String extension) {
    return temporaryVoiceNotePath(extension);
  }

  static Future<List<int>> readRecordingBytes(String path) {
    return readVoiceNoteBytes(path);
  }
}
