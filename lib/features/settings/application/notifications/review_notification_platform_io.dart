import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_local_notifications/flutter_local_notifications.dart";

import "package:smart_expense/features/settings/application/notifications/review_notification_platform.dart";

ReviewNotificationPlatform createPlatform() => _IoNotificationPlatform();

class _IoNotificationPlatform implements ReviewNotificationPlatform {
  static const _reviewPayload = "open_pending_review";
  static const _channelId = "review_reminders";
  static const _channelName = "Nhắc đối soát giao dịch";
  static const _channelDescription =
      "Nhắc kiểm tra các giao dịch đang chờ đối soát.";

  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<void>.broadcast();
  var _initialized = false;
  var _available = true;

  @override
  Stream<void> get taps => _taps.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      android: AndroidInitializationSettings("ic_launcher_foreground"),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    try {
      await _plugin.initialize(
        settings: settings,
        onDidReceiveNotificationResponse: (response) {
          if (response.payload == _reviewPayload) _taps.add(null);
        },
      );
      final launchDetails = await _plugin.getNotificationAppLaunchDetails();
      if (launchDetails?.didNotificationLaunchApp ?? false) {
        final payload = launchDetails?.notificationResponse?.payload;
        if (payload == _reviewPayload) {
          scheduleMicrotask(() => _taps.add(null));
        }
      }
    } catch (_) {
      _available = false;
    }
    _initialized = true;
  }

  @override
  Future<ReviewNotificationPermissionStatus> permissionStatus() async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return ReviewNotificationPermissionStatus.granted;
    }
    return ReviewNotificationPermissionStatus.defaultStatus;
  }

  @override
  Future<ReviewNotificationPermissionStatus> requestPermission() async {
    await initialize();
    if (!_available) return ReviewNotificationPermissionStatus.unsupported;
    if (defaultTargetPlatform == TargetPlatform.android) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      return granted == true
          ? ReviewNotificationPermissionStatus.granted
          : ReviewNotificationPermissionStatus.denied;
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final granted = await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return granted == true
          ? ReviewNotificationPermissionStatus.granted
          : ReviewNotificationPermissionStatus.denied;
    }
    return ReviewNotificationPermissionStatus.granted;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {
    await initialize();
    if (!_available) return;
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.reminder,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: _reviewPayload,
    );
  }

  @override
  Future<void> cancelReviewReminders() async {
    await initialize();
    if (!_available) return;
    await _plugin.cancelAll();
  }

  @override
  void dispose() {
    _taps.close();
  }
}
