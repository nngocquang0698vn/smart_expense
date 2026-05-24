import "package:flutter_test/flutter_test.dart";
import "package:smart_expense/features/settings/domain/review_reminder_settings.dart";

void main() {
  test("defaults use end of day at 20:30", () {
    const settings = ReviewReminderSettings();

    expect(settings.enabled, isFalse);
    expect(settings.mode, ReviewReminderMode.endOfDay);
    expect(settings.endOfDayReminderTime.label, "20:30");
  });

  test("defaults use interval from 06:00 to 21:00 every 4 hours", () {
    const settings = ReviewReminderSettings(mode: ReviewReminderMode.interval);

    expect(settings.intervalReminderStartTime.label, "06:00");
    expect(settings.intervalReminderEndTime.label, "21:00");
    expect(settings.intervalReminderHours, 4);
  });

  test("validates interval time ordering and reasonable interval range", () {
    const badTime = ReviewReminderSettings(
      mode: ReviewReminderMode.interval,
      intervalReminderStartTime: ReviewReminderTime(hour: 21, minute: 0),
      intervalReminderEndTime: ReviewReminderTime(hour: 6, minute: 0),
    );
    expect(
      badTime.validate(),
      contains("Giờ bắt đầu phải trước giờ kết thúc."),
    );

    const badInterval = ReviewReminderSettings(intervalReminderHours: 13);
    expect(
      badInterval.validate(),
      contains("Khoảng lặp nên từ 1 đến 12 tiếng."),
    );
  });

  test("interval larger than selected window is a warning, not invalid", () {
    const settings = ReviewReminderSettings(
      mode: ReviewReminderMode.interval,
      intervalReminderStartTime: ReviewReminderTime(hour: 8, minute: 0),
      intervalReminderEndTime: ReviewReminderTime(hour: 9, minute: 0),
      intervalReminderHours: 4,
    );

    expect(settings.validate(), isEmpty);
    expect(
      settings.warnings(),
      contains("Khung giờ này quá ngắn so với khoảng lặp đã chọn."),
    );
  });

  test("serializes and restores custom reminder settings", () {
    const settings = ReviewReminderSettings(
      enabled: true,
      mode: ReviewReminderMode.interval,
      intervalReminderHours: 6,
      endOfDayReminderTime: ReviewReminderTime(hour: 19, minute: 45),
    );

    expect(ReviewReminderSettings.fromJson(settings.toJson()), settings);
  });
}
