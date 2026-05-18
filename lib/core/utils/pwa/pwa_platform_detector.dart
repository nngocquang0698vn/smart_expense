import "package:flutter/foundation.dart";

import "package:smart_expense/core/utils/pwa/pwa_platform_kind.dart";

/// Detects browser/platform for PWA install UX (pure Dart, testable).
abstract final class PwaPlatformDetector {
  static PwaPlatformKind detect({required String? userAgent, bool? isWeb}) {
    if (!(isWeb ?? kIsWeb)) return PwaPlatformKind.unsupported;
    final ua = (userAgent ?? "").toLowerCase();
    if (ua.isEmpty) return PwaPlatformKind.otherWeb;

    final isIos =
        ua.contains("iphone") || ua.contains("ipad") || ua.contains("ipod");
    final isAndroid = ua.contains("android");
    final isCrios = ua.contains("crios");
    final isFxiOS = ua.contains("fxios");
    final isEdgiOS = ua.contains("edgios");

    if (isIos && !isCrios && !isFxiOS && !isEdgiOS) {
      return PwaPlatformKind.iosSafari;
    }
    if (isAndroid && (ua.contains("chrome") || ua.contains("crios"))) {
      return PwaPlatformKind.androidChrome;
    }
    if (!isAndroid &&
        !isIos &&
        (ua.contains("chrome") ||
            ua.contains("edg/") ||
            ua.contains("edgios") ||
            ua.contains("crios"))) {
      return PwaPlatformKind.desktopChromium;
    }
    return PwaPlatformKind.otherWeb;
  }

  static bool showsInstallBanner(PwaPlatformKind kind) {
    return kind == PwaPlatformKind.androidChrome ||
        kind == PwaPlatformKind.iosSafari ||
        kind == PwaPlatformKind.desktopChromium;
  }
}
