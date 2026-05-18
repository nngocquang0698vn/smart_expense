import "dart:io";

import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

import "package:smart_expense/core/storage/audio_storage_helper.dart";
import "package:smart_expense/features/transactions/data/attachments/voice_playback_source_service.dart";

Future<VoicePlaybackSource> createVoicePlaybackSource(
  List<int> bytes, {
  required String contentType,
}) async {
  final dir = await getTemporaryDirectory();
  final ext = AudioStorageHelper.extensionForBytes(bytes);
  final path = p.join(
    dir.path,
    "voice_playback_${DateTime.now().microsecondsSinceEpoch}$ext",
  );
  await File(path).writeAsBytes(bytes, flush: true);
  return VoicePlaybackSource.file(path);
}

Future<void> releaseVoicePlaybackSource(VoicePlaybackSource? source) async {
  if (source == null || !source.isFile) return;
  final file = File(source.value);
  if (await file.exists()) {
    await file.delete();
  }
}
