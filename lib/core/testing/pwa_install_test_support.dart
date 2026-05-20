import "package:smart_expense/core/utils/pwa/pwa_install_service.dart";

/// Fake [PwaInstallService] với user-agent tùy chỉnh cho widget test.
class FakePwaInstallService implements PwaInstallService {
  FakePwaInstallService({
    required this.userAgent,
    this.isStandalone = false,
    this.canNativePrompt = true,
  });

  @override
  final bool isStandalone;

  @override
  bool canNativePrompt;

  @override
  final String? userAgent;

  @override
  Future<PwaInstallPromptResult> promptInstall() async =>
      PwaInstallPromptResult.unavailable;
}

const kDesktopChromeUa =
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36";

const kIosSafariUa =
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 "
    "(KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1";

const kAndroidChromeUa =
    "Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 (KHTML, like Gecko) "
    "Chrome/120.0.0.0 Mobile Safari/537.36";
