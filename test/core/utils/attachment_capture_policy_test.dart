import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/utils/attachment_capture_policy.dart";

void main() {
  test("showReceiptCameraButton is true on Android and iOS only", () {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    expect(AttachmentCapturePolicy.showReceiptCameraButton, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(AttachmentCapturePolicy.showReceiptCameraButton, isTrue);

    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    expect(AttachmentCapturePolicy.showReceiptCameraButton, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    expect(AttachmentCapturePolicy.showReceiptCameraButton, isFalse);

    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(AttachmentCapturePolicy.showReceiptCameraButton, isFalse);
  });
}
