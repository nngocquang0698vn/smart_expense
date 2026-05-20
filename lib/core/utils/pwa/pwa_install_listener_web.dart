import "dart:js_interop";

@JS("pwaListenInstallAvailable")
external void _jsListenInstallAvailable(JSFunction callback);

@JS("pwaCancelInstallAvailable")
external void _jsCancelInstallAvailable(JSFunction callback);

@JS("pwaListenInstalled")
external void _jsListenInstalled(JSFunction callback);

@JS("pwaCancelInstalled")
external void _jsCancelInstalled(JSFunction callback);

JSFunction? _availableCallback;
JSFunction? _installedCallback;

void listenPwaInstallAvailable(void Function() onAvailable) {
  cancelPwaInstallAvailableListener();
  _availableCallback = onAvailable.toJS;
  _jsListenInstallAvailable(_availableCallback!);
}

void cancelPwaInstallAvailableListener() {
  final callback = _availableCallback;
  if (callback != null) {
    _jsCancelInstallAvailable(callback);
    _availableCallback = null;
  }
}

void listenPwaInstalled(void Function() onInstalled) {
  cancelPwaInstalledListener();
  _installedCallback = onInstalled.toJS;
  _jsListenInstalled(_installedCallback!);
}

void cancelPwaInstalledListener() {
  final callback = _installedCallback;
  if (callback != null) {
    _jsCancelInstalled(callback);
    _installedCallback = null;
  }
}
