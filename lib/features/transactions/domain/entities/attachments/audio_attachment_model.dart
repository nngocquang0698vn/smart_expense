class AudioAttachmentModel {
  const AudioAttachmentModel({
    required this.id,
    this.path,
    this.bundleAssetPath,
    required this.durationMs,
    required this.createdAt,
    required this.mimeType,
    required this.extension,
    required this.fileSize,
  });

  final String id;
  final String? path;

  /// Flutter asset path for bundled seed/demo audio (stable across Web deploy).
  final String? bundleAssetPath;
  final int durationMs;
  final DateTime createdAt;
  final String mimeType;
  final String extension;
  final int fileSize;

  Duration get duration => Duration(milliseconds: durationMs);

  Map<String, Object?> toMap() => {
    "id": id,
    "path": path,
    "bundleAssetPath": bundleAssetPath,
    "durationMs": durationMs,
    "createdAt": createdAt.toIso8601String(),
    "mimeType": mimeType,
    "extension": extension,
    "fileSize": fileSize,
  };

  static AudioAttachmentModel? fromMap(Object? raw) {
    if (raw is! Map) return null;
    return AudioAttachmentModel(
      id: raw["id"] as String,
      path: raw["path"] as String?,
      bundleAssetPath: raw["bundleAssetPath"] as String?,
      durationMs: (raw["durationMs"] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(raw["createdAt"] as String? ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
      mimeType: raw["mimeType"] as String? ?? "audio/*",
      extension: raw["extension"] as String? ?? "",
      fileSize: (raw["fileSize"] as num?)?.toInt() ?? 0,
    );
  }
}
