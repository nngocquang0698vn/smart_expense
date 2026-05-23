import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/seed/seed_assets.dart";
import "package:smart_expense/core/seed/seed_attachments.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group("SeedAttachments", () {
    test("voiceNote uses stable bundled asset path and mime", () {
      final audio = SeedAttachments.voiceNote(fileSize: 1234);
      expect(audio.id, "seed_audio_voice_note");
      expect(audio.bundleAssetPath, SeedAssets.voiceNoteMp3);
      expect(audio.mimeType, "audio/mpeg");
      expect(audio.extension, ".mp3");
      expect(audio.fileSize, 1234);
      expect(audio.path, isNull);
    });

    test("billImage uses stable bundled asset path", () {
      final image = SeedAttachments.billImage(
        width: 800,
        height: 600,
        fileSize: 99,
      );
      expect(image.id, "seed_image_bill");
      expect(image.bundleAssetPath, SeedAssets.billJpg);
      expect(image.path, isNull);
    });

    test("models round-trip through map serialization", () {
      final audio = SeedAttachments.voiceNote(fileSize: 1);
      final restoredAudio = AudioAttachmentModel.fromMap(audio.toMap());
      expect(restoredAudio?.bundleAssetPath, SeedAssets.voiceNoteMp3);

      final image = SeedAttachments.billImage(
        width: 1,
        height: 1,
        fileSize: 1,
      );
      final restoredImage = ImageAttachmentModel.fromMap(image.toMap());
      expect(restoredImage?.bundleAssetPath, SeedAssets.billJpg);
    });

    test("loadMeta reads registered seed assets", () async {
      final meta = await SeedAttachments.loadMeta();
      expect(meta.voiceNoteFileSize, greaterThan(0));
      expect(meta.billFileSize, greaterThan(0));
      expect(meta.billWidth, greaterThan(0));
      expect(meta.billHeight, greaterThan(0));
    });
  });
}
