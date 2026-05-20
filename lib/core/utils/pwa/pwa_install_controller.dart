import "package:flutter/foundation.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/core/utils/pwa/pwa_install_banner_logic.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_state.dart";
import "package:smart_expense/core/utils/pwa/pwa_install_storage.dart";
import "package:smart_expense/core/utils/pwa/pwa_platform_detector.dart";
import "package:smart_expense/core/utils/pwa/pwa_providers.dart";

/// Orchestrates PWA install eligibility, dismiss rules, and native install.
class PwaInstallController extends Notifier<PwaInstallState> {
  @override
  PwaInstallState build() => _composeState();

  PwaInstallStorage get _storage => ref.read(pwaInstallStorageProvider);

  PwaInstallService get _service => ref.read(pwaInstallServiceProvider);

  /// Web khi chạy Flutter web hoặc service cung cấp user-agent (widget test).
  static bool isWebContext(PwaInstallService service) {
    return kIsWeb ||
        (service.userAgent != null && service.userAgent!.isNotEmpty);
  }

  PwaInstallState _composeState({bool? showPostActionCta}) {
    final service = ref.watch(pwaInstallServiceProvider);
    final storage = ref.watch(pwaInstallStorageProvider);
    final platform = PwaPlatformDetector.detect(
      userAgent: service.userAgent,
      isWeb: isWebContext(service),
    );
    final standalone = service.isStandalone;
    final installed = storage.isInstalled || standalone;

    return PwaInstallState(
      platform: platform,
      canNativeInstall: service.canNativePrompt,
      isStandalone: standalone,
      isInstalled: installed,
      canShowAutoPrompt: storage.canShowAutoPrompt && !installed,
      dismissCount: storage.dismissCount,
      showPostActionCta: showPostActionCta ?? false,
    );
  }

  void refresh({bool? keepPostActionCta}) {
    final keep = keepPostActionCta ?? state.showPostActionCta;
    state = _composeState(showPostActionCta: keep);
  }

  Future<void> recordSession() async {
    await _storage.recordSession();
    refresh();
  }

  Future<void> recordDismiss() async {
    await _storage.recordDismiss();
    refresh();
  }

  Future<void> markInstalled() async {
    await _storage.markInstalled();
    refresh();
  }

  Future<PwaInstallPromptResult> install() => _service.promptInstall();

  Future<void> onInstallAccepted() async {
    await markInstalled();
  }

  bool shouldShowOnboardingHint({bool? isWeb}) {
    final web = isWeb ?? kIsWeb;
    return PwaInstallBannerLogic.shouldShowOnboardingHint(
      isWeb: web,
      isStandalone: _service.isStandalone,
      isInstalled: state.isInstalledMode,
      platform: state.platform,
    );
  }

  bool shouldShowOnboardingCard({bool? isWeb}) {
    final web = isWeb ?? kIsWeb;
    return PwaInstallBannerLogic.shouldShowOnboardingCard(
      isWeb: web,
      isStandalone: _service.isStandalone,
      isInstalled: state.isInstalledMode,
      canShowAutoPrompt: state.canShowAutoPrompt,
      platform: state.platform,
    );
  }

  /// After the first complete (non-pending) transaction on web.
  Future<void> onFirstCompleteTransactionSaved({
    required bool pending,
    required bool complete,
    bool? isWeb,
  }) async {
    if (!(isWeb ?? kIsWeb) || pending || !complete) return;
    final isFirst = await _storage.markFirstCompleteTransactionSaved();
    if (!isFirst) return;
    schedulePostActionCta();
  }

  void schedulePostActionCta({bool? isWeb}) {
    final web = isWeb ?? kIsWeb;
    if (_storage.postActionCtaShown) return;
    final platform = PwaPlatformDetector.detect(
      userAgent: _service.userAgent,
      isWeb: web && isWebContext(_service),
    );
    final show = PwaInstallBannerLogic.shouldShowPostActionCta(
      isWeb: web,
      isStandalone: _service.isStandalone,
      isInstalled: state.isInstalledMode,
      canShowAutoPrompt: state.canShowAutoPrompt,
      alreadyShown: _storage.postActionCtaShown,
      platform: platform,
    );
    if (!show) return;
    state = state.copyWith(showPostActionCta: true);
  }

  Future<void> consumePostActionCta() async {
    await _storage.markPostActionCtaShown();
    state = state.copyWith(showPostActionCta: false);
  }

  Future<void> resetForDebug() => _storage.resetForDebug();
}

final pwaInstallControllerProvider =
    NotifierProvider<PwaInstallController, PwaInstallState>(
      PwaInstallController.new,
    );
