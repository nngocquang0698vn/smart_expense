// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import "dart:async";
import "dart:html" as html;
import "dart:typed_data";

import "package:smart_expense/core/attachments/bundle_attachment_reader.dart";
import "package:smart_expense/features/transactions/domain/entities/attachments/audio_attachment_model.dart";

class AudioStorageService {
  static const _dbName = "smart_expense_audio";
  static const _storeName = "audio_blobs";
  static const _dbVersion = 1;

  Future<AudioAttachmentModel> saveRecording({
    required List<int> bytes,
    required Duration duration,
    required String mimeType,
    required String extension,
  }) async {
    final safeExt = extension.startsWith(".") ? extension : ".$extension";
    final id = "audio_${DateTime.now().microsecondsSinceEpoch}";
    final createdAt = DateTime.now();
    final db = await _open();
    final tx = db.transaction(_storeName, "readwrite");
    tx.objectStore(_storeName).put({
      "id": id,
      "bytes": Uint8List.fromList(bytes),
      "createdAt": createdAt.toIso8601String(),
      "mimeType": mimeType,
      "extension": safeExt,
      "fileSize": bytes.length,
    }, id);
    await _complete(tx);
    db.close();
    return AudioAttachmentModel(
      id: id,
      durationMs: duration.inMilliseconds,
      createdAt: createdAt,
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
    final db = await _open();
    final tx = db.transaction(_storeName, "readonly");
    final raw = await tx.objectStore(_storeName).getObject(audio.id);
    await _complete(tx);
    db.close();
    if (raw is! Map) {
      throw StateError("Không tìm thấy file ghi âm trong trình duyệt.");
    }
    final bytes = raw["bytes"];
    if (bytes is ByteBuffer) return Uint8List.view(bytes);
    if (bytes is Uint8List) return bytes;
    if (bytes is List) return bytes.cast<int>();
    throw StateError("Dữ liệu ghi âm trong trình duyệt không hợp lệ.");
  }

  Future<void> delete(AudioAttachmentModel? audio) async {
    if (audio == null) return;
    final db = await _open();
    final tx = db.transaction(_storeName, "readwrite");
    tx.objectStore(_storeName).delete(audio.id);
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
      completer.completeError(tx.error ?? "Không ghi được dữ liệu audio.");
    });
    tx.onAbort.listen((_) {
      completer.completeError(tx.error ?? "Đã huỷ thao tác audio.");
    });
    return completer.future;
  }
}
