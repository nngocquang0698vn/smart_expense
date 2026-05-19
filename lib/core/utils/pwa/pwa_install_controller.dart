import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/pwa/pwa_install_banner_logic.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_prefs.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_state.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_detector.dart";
import "package:smart_expense/core/utils/pwa/pwa_providers.dart";

/// Orchestrates when to show the PWA install banner and install actions.
class PwaInstallController extends Notifier<PwaInstallState> {
  @override
  PwaInstallState build() {
    final service = ref.watch(pwaInstallServiceProvider);
    final platform = PwaPlatformDetector.detect(
      userAgent: service.userAgent,
    );
    return PwaInstallState(
      platform: platform,
      canNativeInstall: service.canNativePrompt,
      isStandalone: service.isStandalone,
    );
  }

  PwaInstallPrefs get _prefs => ref.read(pwaInstallPrefsProvider);

  PwaInstallService get _service => ref.read(pwaInstallServiceProvider);

  /// Call after first frame on web when user has finished app onboarding.
  ///
  /// [isWeb] overrides [kIsWeb] for unit tests.
  void evaluateBanner({bool? isWeb}) {
    final web = isWeb ?? kIsWeb;
    final platform = PwaPlatformDetector.detect(
      userAgent: _service.userAgent,
      isWeb: web,
    );
    final visible = PwaInstallBannerLogic.shouldShowBanner(
      isWeb: web,
      isStandalone: _service.isStandalone,
      canShowFromPrefs: _prefs.canShowBanner,
      platform: platform,
    );
    if (state.bannerVisible == visible &&
        state.platform == platform) {
      return;
    }
    state = state.copyWith(bannerVisible: visible, platform: platform);
  }

  void hideBanner() {
    if (!state.bannerVisible) return;
    state = state.copyWith(bannerVisible: false);
  }

  Future<void> snooze() async {
    await _prefs.snooze();
    hideBanner();
  }

  Future<void> neverShowAgain() async {
    await _prefs.setNeverShow();
    hideBanner();
  }

  Future<PwaInstallPromptResult> install() => _service.promptInstall();

  Future<void> onInstallAccepted() async {
    await _prefs.setNeverShow();
    hideBanner();
  }

  Future<void> resetPromptPreferences() => _prefs.resetPrompt();
}

final pwaInstallControllerProvider =
    NotifierProvider<PwaInstallController, PwaInstallState>(
      PwaInstallController.new,
    );
