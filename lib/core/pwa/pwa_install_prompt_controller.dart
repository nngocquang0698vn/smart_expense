import "package:flutter/foundation.dart";

import "pwa_install_prefs.dart";
import "pwa_install_service.dart";
import "pwa_platform_detector.dart";
import "pwa_platform_kind.dart";

/// Orchestrates when to show the PWA install banner and install actions.
class PwaInstallPromptController extends ChangeNotifier {
  PwaInstallPromptController({
    required PwaInstallService installService,
    required PwaInstallPrefs prefs,
  }) : _installService = installService,
       _prefs = prefs {
    _refreshPlatform();
  }

  void _refreshPlatform() {
    _platform = PwaPlatformDetector.detect(
      userAgent: _installService.userAgent,
    );
  }

  final PwaInstallService _installService;
  final PwaInstallPrefs _prefs;

  late final PwaPlatformKind _platform;
  bool _bannerVisible = false;

  PwaPlatformKind get platform => _platform;

  bool get bannerVisible => _bannerVisible;

  bool get canNativeInstall => _installService.canNativePrompt;

  bool get isStandalone => _installService.isStandalone;

  /// Call after first frame on web when user has finished app onboarding.
  void evaluateBanner() {
    if (!kIsWeb) {
      _bannerVisible = false;
      return;
    }
    if (_installService.isStandalone) {
      _bannerVisible = false;
      notifyListeners();
      return;
    }
    if (!_prefs.canShowBanner) {
      _bannerVisible = false;
      notifyListeners();
      return;
    }
    if (!PwaPlatformDetector.showsInstallBanner(_platform)) {
      _bannerVisible = false;
      notifyListeners();
      return;
    }
    _bannerVisible = true;
    notifyListeners();
  }

  void hideBanner() {
    if (!_bannerVisible) return;
    _bannerVisible = false;
    notifyListeners();
  }

  Future<void> snooze() async {
    await _prefs.snooze();
    hideBanner();
  }

  Future<void> neverShowAgain() async {
    await _prefs.setNeverShow();
    hideBanner();
  }

  Future<PwaInstallPromptResult> install() =>
      _installService.promptInstall();

  Future<void> onInstallAccepted() async {
    await _prefs.setNeverShow();
    hideBanner();
  }

  Future<void> resetPromptPreferences() => _prefs.resetPrompt();
}
