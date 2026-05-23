import "package:flutter/foundation.dart";

/// Quy tắc hiển thị nút chụp ảnh hoá đơn theo thiết bị.
abstract final class AttachmentCapturePolicy {
  /// `true` trên Android/iOS (app native và web/PWA trên điện thoại).
  ///
  /// Flutter web suy ra [defaultTargetPlatform] từ hệ điều hành trình duyệt,
  /// nên Chrome/Safari trên mobile vẫn được coi là Android/iOS.
  /// Desktop (Windows, macOS, Linux) chỉ hiện «Chọn ảnh».
  static bool get showReceiptCameraButton {
    return switch (defaultTargetPlatform) {
      TargetPlatform.android || TargetPlatform.iOS => true,
      _ => false,
    };
  }
}
