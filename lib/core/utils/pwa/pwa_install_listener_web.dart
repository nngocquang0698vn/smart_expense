import "dart:html" as html;

void Function(html.Event)? _handler;

/// Re-runs PWA banner logic when [beforeinstallprompt] fires (often after page load).
void listenPwaInstallAvailable(void Function() onAvailable) {
  cancelPwaInstallAvailableListener();
  _handler = (_) => onAvailable();
  html.window.addEventListener("pwa-install-available", _handler!);
}

void cancelPwaInstallAvailableListener() {
  final handler = _handler;
  if (handler != null) {
    html.window.removeEventListener("pwa-install-available", handler);
    _handler = null;
  }
}
