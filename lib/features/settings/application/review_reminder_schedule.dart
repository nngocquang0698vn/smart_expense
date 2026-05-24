import "package:smart_expense/features/settings/domain/review_reminder_settings.dart";

class ReviewReminderSchedule {
  const ReviewReminderSchedule();

  DateTime? nextCheckAfter(DateTime now, ReviewReminderSettings settings) {
    if (!settings.enabled || settings.validate().isNotEmpty) return null;
    return switch (settings.mode) {
      ReviewReminderMode.endOfDay => _nextEndOfDay(now, settings),
      ReviewReminderMode.interval => _nextInterval(now, settings),
    };
  }

  DateTime _nextEndOfDay(DateTime now, ReviewReminderSettings settings) {
    final today = settings.endOfDayReminderTime.onDate(now);
    if (today.isAfter(now)) return today;
    return settings.endOfDayReminderTime.onDate(
      now.add(const Duration(days: 1)),
    );
  }

  DateTime _nextInterval(DateTime now, ReviewReminderSettings settings) {
    final startToday = settings.intervalReminderStartTime.onDate(now);
    final endToday = settings.intervalReminderEndTime.onDate(now);
    final interval = Duration(hours: settings.intervalReminderHours);
    if (now.isBefore(startToday)) return startToday;
    var cursor = startToday;
    while (!cursor.isAfter(endToday)) {
      if (cursor.isAfter(now)) return cursor;
      cursor = cursor.add(interval);
    }
    return settings.intervalReminderStartTime.onDate(
      now.add(const Duration(days: 1)),
    );
  }
}
