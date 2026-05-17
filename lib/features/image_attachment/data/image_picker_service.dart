import "dart:typed_data";
import "dart:ui" as ui;

import "package:image_picker/image_picker.dart";
import "package:path/path.dart" as p;

import "../domain/image_attachment_model.dart";
import "image_storage_service.dart";

class PickedImageAttachment {
  const PickedImageAttachment({required this.image, required this.bytes});

  final ImageAttachmentModel image;
  final Uint8List bytes;
}

class ImagePickerService {
  ImagePickerService({ImagePicker? picker, ImageStorageService? storage})
    : _picker = picker ?? ImagePicker(),
      _storage = storage ?? ImageStorageService();

  static const double maxWidth = 1600;
  static const int jpegQuality = 82;

  final ImagePicker _picker;
  final ImageStorageService _storage;

  Future<PickedImageAttachment?> pick(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: maxWidth,
      imageQuality: jpegQuality,
      requestFullMetadata: false,
    );
    if (file == null) return null;

    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      throw StateError("Ảnh đang trống. Vui lòng chọn ảnh khác.");
    }

    final size = await _decodeSize(bytes);
    final mimeType = _mimeType(file, bytes);
    final extension = _extension(file, mimeType);
    final image = await _storage.save(
      bytes: bytes,
      mimeType: mimeType,
      extension: extension,
      width: size.width,
      height: size.height,
    );
    return PickedImageAttachment(image: image, bytes: bytes);
  }

  Future<({int width, int height})> _decodeSize(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final size = (width: image.width, height: image.height);
    image.dispose();
    codec.dispose();
    return size;
  }

  String _mimeType(XFile file, Uint8List bytes) {
    if ((file.mimeType ?? "").isNotEmpty) return file.mimeType!;
    if (_isPng(bytes)) return "image/png";
    if (_isWebp(bytes)) return "image/webp";
    return "image/jpeg";
  }

  String _extension(XFile file, String mimeType) {
    final ext = p.extension(file.name).toLowerCase();
    if (ext == ".jpg" || ext == ".jpeg" || ext == ".png" || ext == ".webp") {
      return ext == ".jpeg" ? ".jpg" : ext;
    }
    return switch (mimeType) {
      "image/png" => ".png",
      "image/webp" => ".webp",
      _ => ".jpg",
    };
  }

  bool _isPng(Uint8List bytes) {
    return bytes.length >= 4 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  bool _isWebp(Uint8List bytes) {
    return bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
  }
}
