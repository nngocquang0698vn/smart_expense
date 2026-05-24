import "dart:async";
import "dart:js_interop";

import "package:smart_expense/features/settings/application/notifications/review_notification_platform.dart";

@JS("reviewNotificationSupported")
external bool _notificationSupported();

@JS("reviewNotificationPermission")
external JSString _notificationPermission();

@JS("reviewNotificationRequestPermission")
external JSPromise<JSString> _requestNotificationPermission();

@JS("reviewNotificationSetTapHandler")
external void _setNotificationTapHandler(JSFunction callback);

@JS("reviewNotificationConsumeTap")
external bool _consumeNotificationTap();

@JS("reviewNotificationShow")
external void _showNotification(JSString title, JSString body);

ReviewNotificationPlatform createPlatform() => _WebNotificationPlatform();

class _WebNotificationPlatform implements ReviewNotificationPlatform {
  final _taps = StreamController<void>.broadcast();
  late final JSFunction _tapCallback;
  var _initialized = false;

  @override
  Stream<void> get taps => _taps.stream;

  @override
  Future<void> initialize() async {
    if (!_initialized) {
      _tapCallback = _handleTap.toJS;
      _setNotificationTapHandler(_tapCallback);
      _initialized = true;
    }
    if (_consumeNotificationTap()) _handleTap();
  }

  void _handleTap() {
    if (!_taps.isClosed) _taps.add(null);
  }

  @override
  Future<ReviewNotificationPermissionStatus> permissionStatus() async {
    if (!_notificationSupported()) {
      return ReviewNotificationPermissionStatus.unsupported;
    }
    return _fromWebPermission(_notificationPermission().toDart);
  }

  @override
  Future<ReviewNotificationPermissionStatus> requestPermission() async {
    if (!_notificationSupported()) {
      return ReviewNotificationPermissionStatus.unsupported;
    }
    final permission = (await _requestNotificationPermission().toDart).toDart;
    return _fromWebPermission(permission);
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    _showNotification(title.toJS, body.toJS);
  }

  @override
  Future<void> cancelReviewReminders() async {}

  @override
  void dispose() {
    _taps.close();
  }

  ReviewNotificationPermissionStatus _fromWebPermission(String permission) {
    return switch (permission) {
      "granted" => ReviewNotificationPermissionStatus.granted,
      "denied" => ReviewNotificationPermissionStatus.denied,
      "unsupported" => ReviewNotificationPermissionStatus.unsupported,
      _ => ReviewNotificationPermissionStatus.defaultStatus,
    };
  }
}
