import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";

/// No-op implementation for Android/iOS native and VM tests.
class PwaInstallServiceImpl implements PwaInstallService {
  @override
  bool get isStandalone => false;

  @override
  bool get canNativePrompt => false;

  @override
  String? get userAgent => null;

  @override
  Future<PwaInstallPromptResult> promptInstall() async =>
      PwaInstallPromptResult.unavailable;
}

PwaInstallService createPwaInstallService() => PwaInstallServiceImpl();
