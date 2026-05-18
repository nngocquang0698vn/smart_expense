export "package:smart_expense/core/utils/pwa/pwa_install_service_stub.dart"
    if (dart.library.js_interop) "package:smart_expense/core/utils/pwa/pwa_install_service_web.dart";

/// Result of a native PWA install prompt (Chromium browsers).
enum PwaInstallPromptResult { accepted, dismissed, unavailable }

/// Platform abstraction for PWA install / standalone detection.
abstract class PwaInstallService {
  bool get isStandalone;
  bool get canNativePrompt;
  String? get userAgent;
  Future<PwaInstallPromptResult> promptInstall();
}
