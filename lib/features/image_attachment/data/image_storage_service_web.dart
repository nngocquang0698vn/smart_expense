// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import "dart:async";
import "dart:html" as html;
import "dart:typed_data";

import "../domain/image_attachment_model.dart";

class ImageStorageService {
  static const _dbName = "smart_expense_images";
  static const _storeName = "image_blobs";
  static const _dbVersion = 1;

  Future<ImageAttachmentModel> save({
    required List<int> bytes,
    required String mimeType,
    required String extension,
    required int width,
    required int height,
  }) async {
    final safeExt = extension.startsWith(".") ? extension : ".$extension";
    final id = "image_${DateTime.now().microsecondsSinceEpoch}";
    final now = DateTime.now();
    final db = await _open();
    final tx = db.transaction(_storeName, "readwrite");
    tx.objectStore(_storeName).put({
      "id": id,
      "bytes": Uint8List.fromList(bytes),
      "mimeType": mimeType,
      "extension": safeExt,
      "fileSize": bytes.length,
      "width": width,
      "height": height,
      "createdAt": now.toIso8601String(),
      "updatedAt": now.toIso8601String(),
    }, id);
    await _complete(tx);
    db.close();
    return ImageAttachmentModel(
      id: id,
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
    final db = await _open();
    final tx = db.transaction(_storeName, "readonly");
    final raw = await tx.objectStore(_storeName).getObject(image.id);
    await _complete(tx);
    db.close();
    if (raw is! Map) {
      throw StateError("Không tìm thấy ảnh trong trình duyệt.");
    }
    final bytes = raw["bytes"];
    if (bytes is ByteBuffer) return Uint8List.view(bytes);
    if (bytes is Uint8List) return bytes;
    if (bytes is List) return bytes.cast<int>();
    throw StateError("Dữ liệu ảnh trong trình duyệt không hợp lệ.");
  }

  Future<void> delete(ImageAttachmentModel? image) async {
    if (image == null) return;
    final db = await _open();
    final tx = db.transaction(_storeName, "readwrite");
    tx.objectStore(_storeName).delete(image.id);
    await _complete(tx);
    db.close();
  }

  Future<Map<String, int?>> estimate() async {
    final storage = html.window.navigator.storage;
    if (storage == null) {
      return {"usageBytes": null, "quotaBytes": null};
    }
    final estimate = await storage.estimate() ?? const <String, dynamic>{};
    return {
      "usageBytes": (estimate["usage"] as num?)?.toInt(),
      "quotaBytes": (estimate["quota"] as num?)?.toInt(),
    };
  }

  Future<dynamic> _open() {
    return html.window.indexedDB!.open(
      _dbName,
      version: _dbVersion,
      onUpgradeNeeded: (event) {
        final db = (event.target as dynamic).result;
        if (!db.objectStoreNames!.contains(_storeName)) {
          db.createObjectStore(_storeName);
        }
      },
    );
  }

  Future<void> _complete(dynamic tx) {
    final completer = Completer<void>();
    tx.onComplete.listen((_) => completer.complete());
    tx.onError.listen((_) {
      completer.completeError(tx.error ?? "Không ghi được dữ liệu ảnh.");
    });
    tx.onAbort.listen((_) {
      completer.completeError(tx.error ?? "Đã huỷ thao tác ảnh.");
    });
    return completer.future;
  }
}
