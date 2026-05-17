import "dart:js_interop";

import "pwa_install_service.dart";

@JS("pwaIsStandalone")
external bool _jsPwaIsStandalone();

@JS("pwaInstallAvailable")
external bool _jsPwaInstallAvailable();

@JS("pwaInstallPrompt")
external JSPromise<JSString> _jsPwaInstallPrompt();

@JS("window.navigator.userAgent")
external JSString get _jsUserAgent;

/// Web implementation backed by [web/pwa_install_bridge.js].
class PwaInstallServiceImpl implements PwaInstallService {
  @override
  bool get isStandalone => _jsPwaIsStandalone();

  @override
  bool get canNativePrompt => _jsPwaInstallAvailable();

  @override
  String? get userAgent => _jsUserAgent.toDart;

  @override
  Future<PwaInstallPromptResult> promptInstall() async {
    final outcome = (await _jsPwaInstallPrompt().toDart).toDart;
    return switch (outcome) {
      "accepted" => PwaInstallPromptResult.accepted,
      "dismissed" => PwaInstallPromptResult.dismissed,
      _ => PwaInstallPromptResult.unavailable,
    };
  }
}

PwaInstallService createPwaInstallService() => PwaInstallServiceImpl();
