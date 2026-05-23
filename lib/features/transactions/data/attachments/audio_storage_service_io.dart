import "dart:io";

import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

import "package:smart_expense/core/attachments/bundle_attachment_reader.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";

class AudioStorageService {
  static const _folderName = "smart_expense_audio";

  Future<AudioAttachmentModel> saveRecording({
    required List<int> bytes,
    required Duration duration,
    required String mimeType,
    required String extension,
  }) async {
    final dir = await _audioDirectory();
    final safeExt = extension.startsWith(".") ? extension : ".$extension";
    final id = "audio_${DateTime.now().microsecondsSinceEpoch}";
    final path = p.join(dir.path, "$id$safeExt");
    await File(path).writeAsBytes(bytes, flush: true);
    return AudioAttachmentModel(
      id: id,
      path: path,
      durationMs: duration.inMilliseconds,
      createdAt: DateTime.now(),
      mimeType: mimeType,
      extension: safeExt,
      fileSize: bytes.length,
    );
  }

  Future<List<int>> read(AudioAttachmentModel audio) async {
    final bundlePath = audio.bundleAssetPath;
    if (bundlePath != null && bundlePath.isNotEmpty) {
      return BundleAttachmentReader.read(bundlePath);
    }
    final path = audio.path;
    if (path == null || path.isEmpty) {
      throw StateError("Không tìm thấy đường dẫn file ghi âm.");
    }
    final file = File(path);
    if (!await file.exists()) {
      throw StateError("File ghi âm không còn tồn tại.");
    }
    return file.readAsBytes();
  }

  Future<String> filePath(AudioAttachmentModel audio) async {
    final path = audio.path;
    if (path == null || path.isEmpty || !await File(path).exists()) {
      throw StateError("File ghi âm không còn tồn tại.");
    }
    return path;
  }

  Future<void> delete(AudioAttachmentModel? audio) async {
    final path = audio?.path;
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Map<String, int?>> estimate() async {
    final dir = await _audioDirectory();
    var used = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        used += await entity.length();
      }
    }
    return {"usageBytes": used, "quotaBytes": null};
  }

  Future<Directory> _audioDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
