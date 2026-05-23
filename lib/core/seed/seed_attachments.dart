import "dart:typed_data";
import "dart:ui" as ui;

import "package:flutter/services.dart";

import "package:smart_expense/core/seed/seed_assets.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";

/// Builds seed attachment models backed by bundled assets (no IndexedDB copy).
///
/// Playback/display resolves bytes from [bundleAssetPath] at use time, which
/// keeps demo audio working on Web/PWA/iOS Safari after Cloudflare deploy.
abstract final class SeedAttachments {
  static const _seedCreatedAt = "2026-01-01T00:00:00.000";

  static final DateTime _createdAt =
      DateTime.parse(_seedCreatedAt);

  static const _voiceNoteDurationMs = 8000;
  static const _voiceNoteMime = "audio/mpeg";
  static const _voiceNoteExtension = ".mp3";

  static AudioAttachmentModel voiceNote({int? fileSize}) {
    return AudioAttachmentModel(
      id: "seed_audio_voice_note",
      bundleAssetPath: SeedAssets.voiceNoteMp3,
      durationMs: _voiceNoteDurationMs,
      createdAt: _createdAt,
      mimeType: _voiceNoteMime,
      extension: _voiceNoteExtension,
      fileSize: fileSize ?? 0,
    );
  }

  static ImageAttachmentModel billImage({
    required int width,
    required int height,
    int? fileSize,
  }) {
    return ImageAttachmentModel(
      id: "seed_image_bill",
      bundleAssetPath: SeedAssets.billJpg,
      mimeType: "image/jpeg",
      extension: ".jpg",
      fileSize: fileSize ?? 0,
      width: width,
      height: height,
      createdAt: _createdAt,
    );
  }

  /// Loads bundle metadata once for seeding (file sizes + image dimensions).
  static Future<SeedAttachmentMeta> loadMeta() async {
    final audioBytes = await rootBundle.load(SeedAssets.voiceNoteMp3);
    final imageBytes = await rootBundle.load(SeedAssets.billJpg);
    final imageData = imageBytes.buffer.asUint8List();
    final size = await _decodeImageSize(imageData);
    return SeedAttachmentMeta(
      voiceNoteFileSize: audioBytes.lengthInBytes,
      billFileSize: imageBytes.lengthInBytes,
      billWidth: size.width,
      billHeight: size.height,
    );
  }
}

class SeedAttachmentMeta {
  const SeedAttachmentMeta({
    required this.voiceNoteFileSize,
    required this.billFileSize,
    required this.billWidth,
    required this.billHeight,
  });

  final int voiceNoteFileSize;
  final int billFileSize;
  final int billWidth;
  final int billHeight;

  AudioAttachmentModel voiceNote() {
    return SeedAttachments.voiceNote(fileSize: voiceNoteFileSize);
  }

  ImageAttachmentModel billImage() {
    return SeedAttachments.billImage(
      width: billWidth,
      height: billHeight,
      fileSize: billFileSize,
    );
  }
}

Future<({int width, int height})> _decodeImageSize(List<int> bytes) async {
  final codec = await ui.instantiateImageCodec(
    Uint8List.fromList(bytes),
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final size = (width: image.width, height: image.height);
  image.dispose();
  codec.dispose();
  return size;
}
