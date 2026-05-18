class ImageAttachmentModel {
  const ImageAttachmentModel({
    required this.id,
    this.path,
    required this.mimeType,
    required this.extension,
    required this.fileSize,
    required this.width,
    required this.height,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? path;
  final String mimeType;
  final String extension;
  final int fileSize;
  final int width;
  final int height;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, Object?> toMap() => {
    "id": id,
    "path": path,
    "mimeType": mimeType,
    "extension": extension,
    "fileSize": fileSize,
    "width": width,
    "height": height,
    "createdAt": createdAt.toIso8601String(),
    "updatedAt": updatedAt?.toIso8601String(),
  };

  static ImageAttachmentModel? fromMap(Object? raw) {
    if (raw is! Map) return null;
    return ImageAttachmentModel(
      id: raw["id"] as String,
      path: raw["path"] as String?,
      mimeType: raw["mimeType"] as String? ?? "image/jpeg",
      extension: raw["extension"] as String? ?? ".jpg",
      fileSize: (raw["fileSize"] as num?)?.toInt() ?? 0,
      width: (raw["width"] as num?)?.toInt() ?? 0,
      height: (raw["height"] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(raw["createdAt"] as String? ?? "") ??
          DateTime.fromMillisecondsSinceEpoch(0),
      updatedAt: DateTime.tryParse(raw["updatedAt"] as String? ?? ""),
    );
  }
}
