import "dart:async";

import "package:flutter_riverpod/flutter_riverpod.dart";

import "package:smart_expense/app/providers.dart";
import "package:smart_expense/features/settings/application/notifications/review_notification_platform.dart";
import "package:smart_expense/features/settings/application/review_reminder_notification_service.dart";
import "package:smart_expense/features/settings/application/review_reminder_schedule.dart";
import "package:smart_expense/features/settings/application/user_preferences_controller.dart";
import "package:smart_expense/features/settings/domain/review_reminder_settings.dart";
import "package:smart_expense/features/settings/domain/user_preferences.dart";
import "package:smart_expense/features/transactions/domain/entities/date_filter.dart";
import "package:smart_expense/features/transactions/domain/repositories/ledger_repository.dart";

final reviewNotificationPlatformProvider = Provider<ReviewNotificationPlatform>(
  (ref) {
    final platform = createReviewNotificationPlatform();
    ref.onDispose(platform.dispose);
    return platform;
  },
);

final reviewReminderNotificationServiceProvider =
    Provider<ReviewReminderNotificationService>((ref) {
      final service = ReviewReminderNotificationService(
        ref.watch(reviewNotificationPlatformProvider),
      );
      ref.onDispose(service.dispose);
      return service;
    });

final reviewNotificationTapProvider = StreamProvider<void>((ref) {
  final service = ref.watch(reviewReminderNotificationServiceProvider);
  return service.taps;
});

final reviewReminderSchedulerProvider =
    NotifierProvider<
      ReviewReminderSchedulerController,
      ReviewReminderRuntimeState
    >(ReviewReminderSchedulerController.new);

class ReviewReminderRuntimeState {
  const ReviewReminderRuntimeState({
    this.nextCheckAt,
    this.permissionStatus = ReviewNotificationPermissionStatus.defaultStatus,
  });

  final DateTime? nextCheckAt;
  final ReviewNotificationPermissionStatus permissionStatus;

  ReviewReminderRuntimeState copyWith({
    Object? nextCheckAt = _unset,
    ReviewNotificationPermissionStatus? permissionStatus,
  }) {
    return ReviewReminderRuntimeState(
      nextCheckAt: nextCheckAt == _unset
          ? this.nextCheckAt
          : nextCheckAt as DateTime?,
      permissionStatus: permissionStatus ?? this.permissionStatus,
    );
  }

  static const _unset = Object();
}

class ReviewReminderSchedulerController
    extends Notifier<ReviewReminderRuntimeState> {
  final _schedule = const ReviewReminderSchedule();
  Timer? _timer;
  StreamSubscription<void>? _repoSubscription;

  LedgerRepository get _repo => ref.read(ledgerRepositoryProvider);
  ReviewReminderNotificationService get _notification =>
      ref.read(reviewReminderNotificationServiceProvider);
  UserPreferences get _prefs => ref.read(userPreferencesControllerProvider);

  @override
  ReviewReminderRuntimeState build() {
    _notification.initialize();
    ref.listen<UserPreferences>(userPreferencesControllerProvider, (_, _) {
      _reschedule();
    });
    _repoSubscription = _repo.changes.listen((_) => _reschedule());
    ref.onDispose(() {
      _timer?.cancel();
      _repoSubscription?.cancel();
    });
    scheduleMicrotask(_reschedule);
    return const ReviewReminderRuntimeState();
  }

  Future<ReviewNotificationPermissionStatus> requestPermission() async {
    final status = await _notification.requestPermission();
    state = state.copyWith(permissionStatus: status);
    return status;
  }

  Future<void> updateSettings(ReviewReminderSettings settings) async {
    await ref
        .read(userPreferencesControllerProvider.notifier)
        .update(_prefs.copyWith(reviewReminder: settings));
  }

  Future<void> disableReminder() async {
    _timer?.cancel();
    await _notification.cancelProductionReminders();
    await updateSettings(_prefs.reviewReminder.copyWith(enabled: false));
    state = state.copyWith(nextCheckAt: null);
  }

  Future<int> pendingReviewCount() async {
    final pending = await _repo.pendingAll(
      const DateFilterSelection(preset: DateFilterPreset.allTime),
    );
    return pending.length;
  }

  Future<bool> scheduleDemoNotification(Duration delay) async {
    final count = await pendingReviewCount();
    if (count == 0) return false;
    Timer(delay, () async {
      final latestCount = await pendingReviewCount();
      if (latestCount == 0) return;
      await _notification.showReminder(
        id: ReviewReminderNotificationService.demoNotificationId,
        pendingCount: latestCount,
      );
    });
    return true;
  }

  Future<void> _reschedule() async {
    _timer?.cancel();
    final settings = _prefs.reviewReminder;
    if (!settings.enabled || settings.validate().isNotEmpty) {
      await _notification.cancelProductionReminders();
      state = state.copyWith(nextCheckAt: null);
      return;
    }
    final permission = await _notification.permissionStatus();
    state = state.copyWith(permissionStatus: permission);
    if (permission != ReviewNotificationPermissionStatus.granted) {
      state = state.copyWith(nextCheckAt: null);
      return;
    }
    final next = _schedule.nextCheckAfter(DateTime.now(), settings);
    if (next == null) {
      state = state.copyWith(nextCheckAt: null);
      return;
    }
    state = state.copyWith(nextCheckAt: next);
    final delay = next.difference(DateTime.now());
    _timer = Timer(delay.isNegative ? Duration.zero : delay, () async {
      await _sendProductionReminderIfNeeded();
      await _reschedule();
    });
  }

  Future<void> _sendProductionReminderIfNeeded() async {
    final settings = _prefs.reviewReminder;
    if (!settings.enabled || settings.validate().isNotEmpty) return;
    final permission = await _notification.permissionStatus();
    if (permission != ReviewNotificationPermissionStatus.granted) return;
    final count = await pendingReviewCount();
    if (count == 0) return;
    await _notification.showReminder(
      id: ReviewReminderNotificationService.productionNotificationId,
      pendingCount: count,
    );
  }
}
