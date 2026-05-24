import "dart:async";

import "package:smart_expense/features/settings/application/notifications/review_notification_platform.dart";
import "package:smart_expense/features/settings/application/review_reminder_copy.dart";

class ReviewReminderNotificationService {
  ReviewReminderNotificationService(this._platform);

  static const productionNotificationId = 4201;
  static const demoNotificationId = 4202;

  final ReviewNotificationPlatform _platform;

  Stream<void> get taps => _platform.taps;

  Future<void> initialize() => _platform.initialize();

  Future<ReviewNotificationPermissionStatus> permissionStatus() {
    return _platform.permissionStatus();
  }

  Future<ReviewNotificationPermissionStatus> requestPermission() {
    return _platform.requestPermission();
  }

  Future<void> showReminder({required int id, required int pendingCount}) {
    return _platform.show(
      id: id,
      title: ReviewReminderCopy.defaultTitle,
      body: pendingCount > 0
          ? ReviewReminderCopy.bodyForCount(pendingCount)
          : ReviewReminderCopy.fallbackBody,
      payload: "open_pending_review",
    );
  }

  Future<void> cancelProductionReminders() {
    return _platform.cancelReviewReminders();
  }

  void dispose() {
    _platform.dispose();
  }
}
