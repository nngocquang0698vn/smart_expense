import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_detector.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";

void main() {
  test("detects iOS Safari", () {
    const ua =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";
    expect(
      PwaPlatformDetector.detect(userAgent: ua, isWeb: true),
      PwaPlatformKind.iosSafari,
    );
  });

  test("detects Android Chrome", () {
    const ua =
        "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36";
    expect(
      PwaPlatformDetector.detect(userAgent: ua, isWeb: true),
      PwaPlatformKind.androidChrome,
    );
  });

  test("detects desktop Chromium", () {
    const ua =
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";
    expect(
      PwaPlatformDetector.detect(userAgent: ua, isWeb: true),
      PwaPlatformKind.desktopChromium,
    );
  });

  test("showsInstallBanner only for supported browsers", () {
    expect(
      PwaPlatformDetector.showsInstallBanner(PwaPlatformKind.iosSafari),
      isTrue,
    );
    expect(
      PwaPlatformDetector.showsInstallBanner(PwaPlatformKind.otherWeb),
      isFalse,
    );
  });
}
