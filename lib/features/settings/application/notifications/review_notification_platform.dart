import "dart:async";

import "package:smart_expense/features/settings/application/notifications/review_notification_platform_stub.dart"
    if (dart.library.html) "package:smart_expense/features/settings/application/notifications/review_notification_platform_web.dart"
    if (dart.library.io) "package:smart_expense/features/settings/application/notifications/review_notification_platform_io.dart";

enum ReviewNotificationPermissionStatus {
  granted,
  denied,
  defaultStatus,
  unsupported,
}

abstract class ReviewNotificationPlatform {
  Stream<void> get taps;

  Future<void> initialize();
  Future<ReviewNotificationPermissionStatus> permissionStatus();
  Future<ReviewNotificationPermissionStatus> requestPermission();
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required String payload,
  });
  Future<void> cancelReviewReminders();
  void dispose();
}

ReviewNotificationPlatform createReviewNotificationPlatform() {
  return createPlatform();
}
