import "package:flutter/foundation.dart";

/// Quy tắc hiển thị nút chụp ảnh hoá đơn theo nền tảng.
abstract final class AttachmentCapturePolicy {
  /// `true` trên app Android/iOS; `false` trên web và desktop (chỉ chọn ảnh).
  static bool get showReceiptCameraButton {
    if (kIsWeb) return false;
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }
}
