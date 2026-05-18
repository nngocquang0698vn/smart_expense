import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/storage/audio_storage_helper.dart";

void main() {
  group("AudioStorageHelper", () {
    test("isWav detects RIFF header", () {
      expect(AudioStorageHelper.isWav([0x52, 0x49, 0x46, 0x46, 0, 0]), isTrue);
      expect(AudioStorageHelper.isWav([0x1A, 0x45, 0, 0]), isFalse);
    });

    test("isWebm detects EBML header", () {
      expect(AudioStorageHelper.isWebm([0x1A, 0x45, 0xDF, 0xA3]), isTrue);
      expect(AudioStorageHelper.isWebm([0x52, 0x49, 0x46, 0x46]), isFalse);
    });

    test("loadKeyForBytes includes extension", () {
      final wavKey = AudioStorageHelper.loadKeyForBytes([
        0x52,
        0x49,
        0x46,
        0x46,
        ...List.filled(8, 0),
      ]);
      expect(wavKey, endsWith(".wav"));

      final webmKey = AudioStorageHelper.loadKeyForBytes([
        0x1A,
        0x45,
        0xDF,
        0xA3,
        ...List.filled(8, 0),
      ]);
      expect(webmKey, endsWith(".webm"));
    });

    test("recordingRejectedReason only rejects empty bytes", () {
      expect(AudioStorageHelper.recordingRejectedReason([]), isNotNull);
      expect(
        AudioStorageHelper.recordingRejectedReason([0x1A, 0x45, 0, 0]),
        isNull,
      );
    });

    test("contentTypeForBytes maps common audio headers", () {
      expect(
        AudioStorageHelper.contentTypeForBytes([0x52, 0x49, 0x46, 0x46]),
        "audio/wav",
      );
      expect(
        AudioStorageHelper.contentTypeForBytes([0x1A, 0x45, 0xDF, 0xA3]),
        "audio/webm",
      );
    });
  });
}
