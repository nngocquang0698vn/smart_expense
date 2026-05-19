import "dart:js_interop";

@JS("pwaListenInstallAvailable")
external void _jsListenInstallAvailable(JSFunction callback);

@JS("pwaCancelInstallAvailable")
external void _jsCancelInstallAvailable(JSFunction callback);

JSFunction? _callback;

/// Re-runs PWA banner logic when [beforeinstallprompt] fires (often after page load).
void listenPwaInstallAvailable(void Function() onAvailable) {
  cancelPwaInstallAvailableListener();
  _callback = onAvailable.toJS;
  _jsListenInstallAvailable(_callback!);
}

void cancelPwaInstallAvailableListener() {
  final callback = _callback;
  if (callback != null) {
    _jsCancelInstallAvailable(callback);
    _callback = null;
  }
}
