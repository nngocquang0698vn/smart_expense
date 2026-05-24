import "dart:async";

import "package:smart_expense/features/settings/application/notifications/review_notification_platform.dart";

ReviewNotificationPlatform createPlatform() =>
    _UnsupportedNotificationPlatform();

class _UnsupportedNotificationPlatform implements ReviewNotificationPlatform {
  final _taps = StreamController<void>.broadcast();

  @override
  Stream<void> get taps => _taps.stream;

  @override
  Future<void> initialize() async {}

  @override
  Future<ReviewNotificationPermissionStatus> permissionStatus() async {
    return ReviewNotificationPermissionStatus.unsupported;
  }

  @override
  Future<ReviewNotificationPermissionStatus> requestPermission() async {
    return ReviewNotificationPermissionStatus.unsupported;
  }

  @override
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) async {}

  @override
  Future<void> cancelReviewReminders() async {}

  @override
  void dispose() {
    _taps.close();
  }
}
