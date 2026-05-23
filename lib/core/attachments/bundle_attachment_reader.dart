import "package:flutter/services.dart";

/// Reads attachment bytes from Flutter bundle assets (seed/demo media).
abstract final class BundleAttachmentReader {
  static Future<List<int>> read(String bundleAssetPath) async {
    final data = await rootBundle.load(bundleAssetPath);
    return data.buffer.asUint8List();
  }
}
