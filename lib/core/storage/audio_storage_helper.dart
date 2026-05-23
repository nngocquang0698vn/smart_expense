abstract final class AudioStorageHelper {
  static String extensionForBytes(List<int> bytes) {
    if (isWav(bytes)) return ".wav";
    if (isWebm(bytes)) return ".webm";
    if (isMp3(bytes)) return ".mp3";
    if (isOgg(bytes)) return ".ogg";
    return ".m4a";
  }

  static String contentTypeForBytes(List<int> bytes) {
    if (isWav(bytes)) return "audio/wav";
    if (isWebm(bytes)) return "audio/webm";
    if (isMp3(bytes)) return "audio/mpeg";
    if (isOgg(bytes)) return "audio/ogg";
    return "audio/mp4";
  }

  static bool isWav(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46;
  }

  static bool isWebm(List<int> bytes) {
    return bytes.length >= 4 && bytes[0] == 0x1A && bytes[1] == 0x45;
  }

  static bool isMp3(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0x49 &&
        bytes[1] == 0x44 &&
        bytes[2] == 0x33) {
      return true;
    }
    if (bytes.length < 2) return false;
    return bytes[0] == 0xFF && (bytes[1] & 0xE0) == 0xE0;
  }

  static bool isOgg(List<int> bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x4F &&
        bytes[1] == 0x67 &&
        bytes[2] == 0x67 &&
        bytes[3] == 0x53;
  }

  static bool isKnownAudio(List<int> bytes) {
    return bytes.isNotEmpty &&
        (isWav(bytes) || isWebm(bytes) || isMp3(bytes) || isOgg(bytes));
  }

  static String loadKeyForBytes(List<int> bytes) {
    final ext = extensionForBytes(bytes);
    return "vn_${bytes.hashCode}$ext";
  }

  static String? recordingRejectedReason(List<int> bytes) {
    if (bytes.isEmpty) return "Bản ghi trống.";
    return null;
  }

  static String? playbackBlockedReason(List<int> bytes) {
    if (bytes.isEmpty) return "File audio trống.";
    return null;
  }
}
