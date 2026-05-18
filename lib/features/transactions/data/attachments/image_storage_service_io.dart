import "dart:io";

import "package:path/path.dart" as p;
import "package:path_provider/path_provider.dart";

import "package:smart_expense/features/transactions/domain/entities/attachments/image_attachment_model.dart";

class ImageStorageService {
  static const _folderName = "smart_expense_images";

  Future<ImageAttachmentModel> save({
    required List<int> bytes,
    required String mimeType,
    required String extension,
    required int width,
    required int height,
  }) async {
    final dir = await _imageDirectory();
    final safeExt = extension.startsWith(".") ? extension : ".$extension";
    final id = "image_${DateTime.now().microsecondsSinceEpoch}";
    final path = p.join(dir.path, "$id$safeExt");
    await File(path).writeAsBytes(bytes, flush: true);
    final now = DateTime.now();
    return ImageAttachmentModel(
      id: id,
      path: path,
      mimeType: mimeType,
      extension: safeExt,
      fileSize: bytes.length,
      width: width,
      height: height,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<List<int>> read(ImageAttachmentModel image) async {
    final path = image.path;
    if (path == null || path.isEmpty) {
      throw StateError("Không tìm thấy đường dẫn ảnh.");
    }
    final file = File(path);
    if (!await file.exists()) {
      throw StateError("Ảnh không còn tồn tại.");
    }
    return file.readAsBytes();
  }

  Future<void> delete(ImageAttachmentModel? image) async {
    final path = image?.path;
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Map<String, int?>> estimate() async {
    final dir = await _imageDirectory();
    var used = 0;
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is File) used += await entity.length();
    }
    return {"usageBytes": used, "quotaBytes": null};
  }

  Future<Directory> _imageDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, _folderName));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
