import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/settings/application/review_reminder_schedule.dart";
import "package:smart_expense/features/settings/domain/review_reminder_settings.dart";

void main() {
  const schedule = ReviewReminderSchedule();

  test("end of day schedules the configured time", () {
    const settings = ReviewReminderSettings(enabled: true);

    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 9), settings),
      DateTime(2026, 5, 24, 20, 30),
    );
    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 21), settings),
      DateTime(2026, 5, 25, 20, 30),
    );
  });

  test("disabled or invalid settings do not schedule checks", () {
    const disabled = ReviewReminderSettings();
    const invalid = ReviewReminderSettings(
      enabled: true,
      intervalReminderStartTime: ReviewReminderTime(hour: 21, minute: 0),
      intervalReminderEndTime: ReviewReminderTime(hour: 6, minute: 0),
    );

    expect(schedule.nextCheckAfter(DateTime(2026, 5, 24, 9), disabled), isNull);
    expect(schedule.nextCheckAfter(DateTime(2026, 5, 24, 9), invalid), isNull);
  });

  test("end of day exact reminder time schedules tomorrow", () {
    const settings = ReviewReminderSettings(enabled: true);

    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 20, 29), settings),
      DateTime(2026, 5, 24, 20, 30),
    );
    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 20, 30), settings),
      DateTime(2026, 5, 25, 20, 30),
    );
  });

  test("custom end of day time is respected", () {
    const settings = ReviewReminderSettings(
      enabled: true,
      endOfDayReminderTime: ReviewReminderTime(hour: 19, minute: 15),
    );

    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 9), settings),
      DateTime(2026, 5, 24, 19, 15),
    );
  });

  test("default interval checks 06:00, 10:00, 14:00 and 18:00", () {
    const settings = ReviewReminderSettings(
      enabled: true,
      mode: ReviewReminderMode.interval,
    );

    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 5, 30), settings),
      DateTime(2026, 5, 24, 6),
    );
    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 6), settings),
      DateTime(2026, 5, 24, 10),
    );
    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 18), settings),
      DateTime(2026, 5, 25, 6),
    );
  });

  test("interval schedules exact window end only before that time", () {
    const settings = ReviewReminderSettings(
      enabled: true,
      mode: ReviewReminderMode.interval,
      intervalReminderEndTime: ReviewReminderTime(hour: 18, minute: 0),
    );

    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 17, 59), settings),
      DateTime(2026, 5, 24, 18),
    );
    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 18), settings),
      DateTime(2026, 5, 25, 6),
    );
  });

  test("custom interval hours are respected and outside window is skipped", () {
    const settings = ReviewReminderSettings(
      enabled: true,
      mode: ReviewReminderMode.interval,
      intervalReminderHours: 3,
    );

    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 10), settings),
      DateTime(2026, 5, 24, 12),
    );
    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 22), settings),
      DateTime(2026, 5, 25, 6),
    );
  });

  test("short valid interval window schedules start then tomorrow", () {
    const settings = ReviewReminderSettings(
      enabled: true,
      mode: ReviewReminderMode.interval,
      intervalReminderStartTime: ReviewReminderTime(hour: 8, minute: 15),
      intervalReminderEndTime: ReviewReminderTime(hour: 9, minute: 0),
      intervalReminderHours: 4,
    );

    expect(settings.validate(), isEmpty);
    expect(settings.warnings(), isNotEmpty);
    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 7, 30), settings),
      DateTime(2026, 5, 24, 8, 15),
    );
    expect(
      schedule.nextCheckAfter(DateTime(2026, 5, 24, 8, 15), settings),
      DateTime(2026, 5, 25, 8, 15),
    );
  });
}
